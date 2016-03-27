delete global.Promise;
require('../enhanced-promises');

describe("Promise Polyfill should work", function() {

  it("should resolve deferred objects", function(done) {
    var deferred = Promise.defer();
    deferred.promise
      .then(function(resolvedValue) {
        expect(resolvedValue).toBe(123);
        done();
      })
      .catch(function() {
      	throw Error('should never run');
      });
      deferred.resolve(123);
  });

  it("should reject deferred objects", function(done) {
    var deferred = Promise.defer();
    deferred.promise
      .then(function() {
      	throw Error('should never run');
      })
      .catch(function(rejectedValue) {
        expect(rejectedValue).toBe(456);
        done();
      });
      deferred.reject(456);
  });

  it("should resolve and evaluate handler in Promise constructor", function(done) {
    new Promise(function(resolve, reject) {
      resolve(123);
    })
    .then(function(resolvedValue) {
      expect(resolvedValue).toBe(123);
      done();
    })
    .catch(function() {
      throw Error('should never run');
    });
  });

  it("should reject and evaluate handler in Promise constructor", function(done) {
    new Promise(function(resolve, reject) {
      reject(123);
    })
    .then(function() {
      throw Error('should never run');
    })
    .catch(function(rejectedValue) {
      expect(rejectedValue).toBe(123);
      done();
    });
  });

  it("should return resolved promise with Promise.resolve wrapper", function(done) {
    Promise.resolve(123)
      .then(function(resolvedValue) {
        expect(resolvedValue).toBe(123);
        done();
      })
      .catch(function() {
        throw Error('should never run');
      });
  });

  it("should reject when constructor handler throws error", function(done) {
    var error = new Error('POW');
    new Promise(function(){ throw error })
      .then(function() {
        throw Error('should never run');
      })
      .catch(function(error) {
        expect(error).toBe(error);
        done();
      });
  });

  it("should reject when .then handler throws error", function(done) {
    var error = new Error('POW');
    Promise.resolve()
      .then(function() {
        throw error;
      })
      .catch(function(error) {
        expect(error).toBe(error);
        done();
      });
  });

  it("should return rejected promise with Promise.reject wrapper", function(done) {
    Promise.reject(123)
      .then(function() {
        throw Error('should never run');
      })
      .catch(function(rejectedValue) {
        expect(rejectedValue).toBe(123);
        done();
      });
  });

  it("Promise.all should resolve when all subpromises resolve", function(done) {
    var deferred = Promise.defer();
    Promise.all([
        123,
        Promise.resolve(456),
        deferred.promise,
        new Promise(function(resolve, reject) { setTimeout(resolve, 10) }),
      ])
      .then(function(resolvedValues) {
        expect(resolvedValues[0]).toBe(123);
        expect(resolvedValues[1]).toBe(456);
        expect(resolvedValues[2]).toBe(789);
        expect(resolvedValues[3]).toBe(undefined);
        done();
      })
      .catch(function(e) {
        throw Error('should never run');
      });
      deferred.resolve(789);
  });

  it("Promise.race should resolve when one subpromises resolve", function(done) {
    var deferred = Promise.defer();
    Promise.race([
        123,
        new Promise(function(resolve, reject) { setTimeout(reject, 1000) }),
      ])
      .then(function(resolvedValues) {
        expect(resolvedValues).toBe(123);
        done();
      })
      .catch(function(e) {
        throw Error('should never run');
      });
  });

  it("Promise.all should reject when one subpromises resolve", function(done) {
    var deferred = Promise.defer();
    Promise.all([
        123,
        Promise.resolve(456),
        deferred.promise,
        new Promise(function(resolve, reject) { setTimeout(reject, 10) }),
      ])
      .then(function(resolvedValues) {
        throw Error('should never run');
      })
      .catch(function(e) {
        done();
      });
      deferred.resolve(789);
  });

  it("Big nasty test should pass", function(done) {
    new Promise(function(resolve, reject) {
      resolve(123);
    })
    .then(function(resolvedValue) {
      expect(rejectedValue).toBe(123);
      return Promise.resolve(456);
    })
    .then(function(resolvedValue) {
      expect(rejectedValue).toBe(456);
      var deferred = Promise.defer();
      setTimeout(function() {
        deferred.resolve(789);
      }, 100);
      return deferred.promise;
    })
    .then(function(resolvedValue) {
      expect(rejectedValue).toBe(789);
      asdasdasd;
    })
    .then(function(resolvedValue) {
      throw Error('should never run');
    })
    .catch(function(rejectedValue) {
      done();
    });
  });

});