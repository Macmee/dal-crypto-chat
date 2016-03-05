Promise.npost = function(object, fn, args) {
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

Promise.ninvoke = function(object, fn  /* , args... */) {
  var args = [].slice.call(arguments, 2);
  return Promise.npost(object, fn, args);
};

Promise.nbind = function(object, fn) {
  return function(/* args... */) {
    var args = [].slice.call(arguments);
    return Promise.npost(object, fn, args);
  };
};

Promise.denodify = function(fn) {
  return function(/* args... */) {
    var args = [].slice.call(arguments);
    return Promise.npost(null, fn, args);
  };
};

Promise.nfapply = function(fn, args) {
  return Promise.npost(null, fn, args);
};

Promise.nfcall = function(fn /* , args... */) {
  var args = [].slice.call(arguments, 1);
  return Promise.npost(null, fn, args);
};

Promise.prototype.spread = function(fn) {
  return this.then(function(argList) {
    if (argList.constructor === Array) {
      return fn.apply(this, argList);
    } else {
      return fn(argList);
    }
  });
};

Promise.delay = function(ms) {
  return new Promise(function(resolve, reject) {
    setTimeout(resolve, ms || 0);
  });
};

Object.defineProperty(Object.getPrototypeOf(Promise.defer()), 'makeNodeResolver', {
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
