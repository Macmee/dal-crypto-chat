(function(global) {

	if (global.Promise) {
		function Promise(handler) {
			console.log('a');
			if (!handler) return;
			try {
				handler(this.resolve.bind(this), this.reject.bind(this));
			} catch (exception) {
				this.reject(exception);
			}
		}

		global.Promise = Promise;

		Promise.defer = function() {
			var deferred = new Promise();
			// promise instances can actually just be deferred objects, so deferred is a promise itself
			deferred.promise = deferred;
			return deferred;
		}

		Promise.toPromise = function(object) {
			if (object instanceof Promise) return object;
			return (object instanceof Error) ? Promise.reject(object) : Promise.resolve(object);
		}

		Promise.resolve = function(object) {
			var promise = new Promise();
			promise.resolvedValue = object;
			return promise;
		}

		Promise.reject = function(object) {
			var promise = new Promise();
			promise.rejectedValue = object;
			promise.rejected = true;
			return promise;
		}

		Promise.prototype.forwarded = false;

		Promise.prototype.isResolved = function() {
			return this.hasOwnProperty('resolvedValue');
		}

		Promise.prototype.isRejected = function() {
			return this.hasOwnProperty('rejected');
		}

		Promise.prototype.hasNextPromise = function() {
			return this.hasOwnProperty('nextPromise');
		}

		Promise.prototype.resolve = function(resolvedValue) {
			// store resolve value, avoid running twice
			if (!this.isResolved()) this.resolvedValue = resolvedValue;
			if (this.forwarded || this.isRejected()) return;
			this.forwarded = true;
			// extract the promise or exception returned from the handler, or no handler may exist (null)
			var thenHandlerPromise;
			var thenHandlerException;
			try {
				thenHandlerPromise = this.thenHandler ? Promise.toPromise(this.thenHandler(this.resolvedValue)) : null;
			} catch (exception) {
				thenHandlerException = exception;
			}
			if (thenHandlerException) {
				// case 1: handler returned an exception, reject promise instead of resolving
				this.reject(thenHandlerException);
			} else if (this.hasNextPromise() && thenHandlerPromise != null) {
				// case 2: this promise has a handler and a next promise, so connect them together
				thenHandlerPromise.catch(this.nextPromise.reject.bind(this.nextPromise));
				thenHandlerPromise.nextPromise = this.nextPromise;
				if (thenHandlerPromise.isResolved()) {
					setTimeout(thenHandlerPromise.resolve.bind(thenHandlerPromise), 0);
				}
			} else if (!this.hasNextPromise() && thenHandlerPromise != null) {
				// case 3: no next promise, but handler had a promise to assign that as next promise
				this.nextPromise = thenHandlerPromise;
			} else if (this.hasNextPromise() && thenHandlerPromise == null) {
				// case 4: we have a next promise but no handler, so just resolve the next promise
				this.nextPromise.resolve();
			} else {
				// case 5: we have no next promise, and no handler, so flag the chain as terminated
				this.chainTerminated = true;
			}
		}

		Promise.prototype.reject = function(rejectedValue) {
			if (this.isRejected()) return;
			this.rejected = true;
			if (this.catchHandler) {
				// case 1: we're rejecting and we have a rejection handler to invoke
				this.rejectionHandled = true;
				this.catchHandler(rejectedValue);
			} else if (this.nextPromise) {
				// case 2: we're rejecting and have a next promise, so propagate the rejection forward
				if (this.nextPromise) this.nextPromise.reject(rejectedValue);
			} else {
				// case 3: we neither have a next promise nor rejection handler, so store the rejected value
				this.rejectedValue = rejectedValue;
			}
		}

		Promise.prototype.then = function(handler) {
			if (this.chainTerminated) {
				return Promise.toPromise(handler(this.resolvedValue));
			}
			// once this handler has resolved, whatever handler returns will resolve/reject the next promise
			if (!this.nextPromise) this.nextPromise = new Promise();
			this.thenHandler = handler;
			if (this.isRejected()) {
				// this promise is already rejected, propagate its rejection on to the next promise
				this.nextPromise.reject(this.rejectedValue);
			} else if (this.isResolved()) {
				console.log('resolved', this.resolvedValue);
				// this promise is already resolved, so resolve it again so that it parses this handler
				setTimeout(this.resolve.bind(this), 0);
			}
			// the next then and catch should now belong to the next promise
			return this.nextPromise;
		}

		Promise.prototype.catch = function(callback) {
			if (this.isRejected() && !this.rejectionHandled) {
				// the promise is already rejected and the rejection hasnt been handled so just run the handler
				callback(this.rejectedValue);
				this.rejectionHandled = true;
			}
			// store the rejection handler for when the promise rejects
			this.catchHandler = callback;
			return this;
		}

	}

	global.Promise.npost = function(object, fn, args) {
	  return new Promise(function(resolve, reject) {
	    args.push(function(err /* , args... */) {
	      if (err) {
	        reject(err);
	      } else {
	        var args = arguments[1];
	        if (arguments.length > 2) {
	          args = [];
	          for(var i = 1; i < arguments.length; i++) args.push(arguments[i]);
	        }
	        resolve(args);
	      }
	    });
	    (typeof fn === 'string' ? object[fn] : fn).apply(object, args);
	  });
	};

	global.Promise.ninvoke = function(object, fn  /* , args... */) {
	  var args = [].slice.call(arguments, 2);
	  return Promise.npost(object, fn, args);
	};

	global.Promise.nbind = function(object, fn) {
	  return function(/* args... */) {
	    var args = [].slice.call(arguments);
	    return Promise.npost(object, fn, args);
	  };
	};

	global.Promise.denodify = function(fn) {
	  return function(/* args... */) {
	    var args = [].slice.call(arguments);
	    return Promise.npost(null, fn, args);
	  };
	};

	global.Promise.nfapply = function(fn, args) {
	  return Promise.npost(null, fn, args);
	};

	global.Promise.nfcall = function(fn /* , args... */) {
	  var args = [].slice.call(arguments, 1);
	  return Promise.npost(null, fn, args);
	};

	global.Promise.prototype.spread = function(fn) {
	  return this.then(function(argList) {
	    if (argList.constructor === Array) {
	      return fn.apply(this, argList);
	    } else {
	      return fn(argList);
	    }
	  });
	};

	global.Promise.delay = function(ms) {
	  return new Promise(function(resolve, reject) {
	    setTimeout(resolve, ms || 0);
	  });
	};

	Object.defineProperty(Object.getPrototypeOf(global.Promise.defer()), 'makeNodeResolver', {
	  enumerable: false,
	  get: function() {
	    var self = this;
	    return function(err /* , args... */) {
	      if (err) {
	        self.reject(err);
	      } else {
	        var args = arguments[1];
	        if (arguments.length > 2) {
	          args = [];
	          for(var i = 1; i < arguments.length; i++) args.push(arguments[i]);
	        }
	        self.resolve(args);
	      }
	    };
	  }
	});

})(typeof global === 'undefined' ? window : global);
