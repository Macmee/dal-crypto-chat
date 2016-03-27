(function(global) {

  if (!global.Promise) {

    function Defer(owner) {
      if (owner) {
        this.promise = owner;
      }
    }

    Defer.prototype.resolved = false;
    Defer.prototype.rejected = false;
    Defer.prototype.resolvedValue = undefined;
    Defer.prototype.rejectedValue = undefined;

    Defer.prototype.resolve = function(value) {
      if (this.resolved || this.rejected) {
        // maybe we should throw an error when double resolving?
      } else {
        this.resolved = true;
        this.resolvedValue = value;
      }
      if (this.promise) {
        this.promise.tick();
      }
    };

    Defer.prototype.reject = function(value) {
      if (this.resolved || this.rejected) {
        // maybe we should throw an error when double rejecting?
      } else {
        this.rejected = true;
        this.rejectedValue = value;
      }
      if (this.promise) {
        this.promise.tick();
      }
    };

    var Promise = global.Promise = function(resolverFn) {
      if (resolverFn) {
        var deferred = this.deferred = new Defer(this);
        try {
          resolverFn(
            deferred.resolve.bind(deferred),
            deferred.reject.bind(deferred)
          );
        } catch (e) {
          deferred.reject(e);
        }
      }
    }

    Promise.prototype.thenMethod = undefined;
    Promise.prototype.thenMethodEvaluated = false;
    Promise.prototype.catchMethodEvaluated = false;
    Promise.prototype.thenMethodResult = undefined;
    Promise.prototype.nextPromise = undefined;
    Promise.prototype.transferred = false;

    Promise.defer = function() {
      var promise = new Promise();
      promise.deferred = new Defer(promise);
      return promise.deferred;
    };

    Promise.toPromise = function(object) {
      if (object instanceof Promise) {
        return object;
      } else if (object instanceof Error) {
        return Promise.reject(object);
      } else {
        return Promise.resolve(object);
      }
    };

    Promise.resolve = function(value) {
      var promise = new Promise();
      var deferred = promise.deferred = new Defer(promise);
      deferred.resolved = true;
      deferred.resolvedValue = value;
      return promise;
    };

    Promise.reject = function(value) {
      var promise = new Promise();
      var deferred = promise.deferred = new Defer(promise);
      deferred.rejected = true;
      deferred.rejectedValue = value;
      return promise;
    };

    Promise.all = function(promises) {
      var results = [];
      var completed = 0;
      var deferred = Promise.defer();
      promises.forEach(function(promise, i) {
        Promise.toPromise(promise)
          .then(function(result) {
            results[i] = result;
            completed++;
            if (completed == promises.length) {
              deferred.resolve(results);
            }
          })
          .catch(function(error) {
            deferred.reject(error);
          });
      });
      return deferred.promise;
    };

    Promise.race = function(promises) {
      var completed = false;
      var deferred = Promise.defer();
      promises.forEach(function(promise, i) {
        Promise.toPromise(promise)
          .then(function(result) {
            if (!completed) {
              completed = true;
              deferred.resolve(result);
            }
          })
          .catch(function(error) {
            if (!completed) {
              completed = true;
              deferred.reject(error);
            }
          });
      });
      return deferred.promise;
    };

    Promise.prototype.tick = function() {
      if (!this.deferred) {
        return;
      }
      if (this.deferred.resolved) {
        if (!this.thenMethodEvaluated && this.thenMethod) {
          try {
            var value = this.thenMethod(this.deferred.resolvedValue);
            this.thenMethodResult = Promise.toPromise(value);
            this.thenMethodEvaluated = true;
          } catch(e) {
            var deferred = this.deferred = new Defer(this);
            deferred.rejected = true;
            deferred.rejectedValue = e;
          }
        }
        if (this.thenMethodEvaluated && this.nextPromise) {
          this.nextPromise.deferred = this.thenMethodResult.deferred;
          this.nextPromise.deferred.promise = this.nextPromise;
          this.nextPromise.tick();
        }
      }
      if (this.deferred.rejected) {
        if (this.catchMethod) {
          if (!this.catchMethodEvaluated) {
            this.catchMethod(this.deferred.rejectedValue);
            this.catchMethodEvaluated = true;
          }
        } else if (this.nextPromise) {
          this.nextPromise.reject(this.deferred.rejectedValue);
        }
      }
    };

    Promise.prototype.resolve = function(value) {
      if (!this.deferred) {
        throw new Error("missing deferred");
      }
      this.deferred.resolve(value);
    };

    Promise.prototype.reject = function(value) {
      if (!this.deferred) {
        this.deferred = new Defer(this);
      }
      this.deferred.reject(value);
    };

    Promise.prototype.catch = function(fn) {
      if (this.catchMethod) {
        throw new Error("already have a catch method");
      }
      this.catchMethod = fn;
      setTimeout(this.tick.bind(this), 0);
      return this;
    };

    Promise.prototype.then = function(fn, rejectedFn) {
      if (this.thenMethod) {
        throw new Error("already have a then method");
      }
      this.thenMethod = fn;
      if (!this.nextPromise) {
        this.nextPromise = new Promise();
      }
      if (rejectedFn) {
        return this.catch(rejectedFn);
      } else {
        setTimeout(this.tick.bind(this), 0);
        return this.nextPromise;
      }
    };

  }

  global.Promise.npost = function(object, fn, args) {
    return new global.Promise(function(resolve, reject) {
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
    return global.Promise.npost(object, fn, args);
  };

  global.Promise.nbind = function(object, fn) {
    return function(/* args... */) {
      var args = [].slice.call(arguments);
      return global.Promise.npost(object, fn, args);
    };
  };

  global.Promise.denodify = function(fn) {
    return function(/* args... */) {
      var args = [].slice.call(arguments);
      return global.Promise.npost(null, fn, args);
    };
  };

  global.Promise.nfapply = function(fn, args) {
    return global.Promise.npost(null, fn, args);
  };

  global.Promise.nfcall = function(fn /* , args... */) {
    var args = [].slice.call(arguments, 1);
    return global.Promise.npost(null, fn, args);
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
    return new global.Promise(function(resolve, reject) {
      setTimeout(resolve, ms || 0);
    });
  };

  global.Promise.fcall = function(fn) {
    var object;
    try {
      object = fn();
    } catch (e) {
      object = e;
    }
    if (object instanceof global.Promise) {
      return object;
    } else if (object instanceof Error) {
      return global.Promise.reject(object);
    } else {
      return global.Promise.resolve(object);
    }
  };

  global.Promise.prototype.all = function() {
    return this.then(function(promiseArray) {
      if (!promiseArray.constructor === Array) {
        promiseArray = [promiseArray];
      }
      return global.Promise.all(promiseArray);
    })
  }

  var originalDefer = global.Promise.defer;
  global.Promise.defer = function() {
    var deferred = originalDefer.call(global.Promise);
    deferred.makeNodeResolver = function() {
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
    return deferred;
  };

  if (!Object.prototype.$promise) {
    Object.defineProperty(Object.prototype, '$promise', {
      enumerable: false,
      get: function() {
        var self = this;
        return function(fn /* , args... */) {
          var args = [].slice.call(arguments, 1);
          return global.Promise.npost(self, fn, args);
        }
      }
    });
  }

  if (typeof module != 'undefined') {
    module.exports = global.Promise;
  }

})(typeof global === 'undefined' ? window : global);
