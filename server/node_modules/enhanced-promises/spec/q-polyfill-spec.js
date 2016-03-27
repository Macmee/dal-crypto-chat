require('../enhanced-promises');

describe("Q Polyfill should work", function() {

  // -- defer

  it("should reject deferred objects", function(done) {
  	var started = Number(new Date);
  	Promise
  	  .delay(1000)
  	  .then(function(resolve) {
  	  	var difference = Number(new Date) - started;
        expect(Math.abs(difference - 1000) < 20).toBe(true);
        done();
  	  })
      .catch(function() {
        throw Error('should never run');
      });
  });

  // -- spread

  it("should spread out array results with spread", function(done) {
    Promise.
      resolve([1,2,3,4,5])
      .spread(function(a,b,c,d,e) {
        expect(a).toBe(1);
        expect(b).toBe(2);
        expect(c).toBe(3);
        expect(d).toBe(4);
        expect(e).toBe(5);
        return 6;
      })
      .then(function(f) {
        expect(f).toBe(6);
        done();
      })
      .catch(function(e) {
        throw Error('should never run');
      });
  });

  var testNodeObject = {
    test: function(param, param2, callback) {
  		setTimeout(function() {
	    callback(null, param + '456' + param2);
      }, 10);
    },
    testFailure: function(param, param2, callback) {
      setTimeout(function() {
      callback(new Error(123), param + '456' + param2);
      }, 10);
    }
  };

  // -- ninvoke

  it("should accept ninvoke objects that dont callback with an error", function(done) {
  	Promise.ninvoke(testNodeObject, 'test', '123', '')
  	  .then(function(resolve) {
        expect(resolve).toBe('123456');
        done();
  	  })
      .catch(function() {
        throw Error('should never run');
      });
  });

  it("should reject ninvoke objects that callback with an error", function(done) {
    Promise.ninvoke(testNodeObject, 'testFailure', '123', '')
      .then(function(resolve) {
        throw Error('should never run');
      })
      .catch(function() {
        done();
      });
  });

  // -- nfcall

  it("should accept nfcall objects that dont callback with an error", function(done) {
    Promise.nfcall(testNodeObject.test.bind(testNodeObject), '123', '789')
      .then(function(resolve) {
        expect(resolve).toBe('123456789');
        done();
      })
      .catch(function() {
        throw Error('should never run');
      });
  });

  it("should reject nfcall objects that callback with an error", function(done) {
    Promise.nfcall(testNodeObject.testFailure.bind(testNodeObject), '123', '789')
      .then(function(resolve) {
        throw Error('should never run');
      })
      .catch(function() {
        done();
      });
  });

  // -- nfapply

  it("should accept nfapply objects that dont callback with an error", function(done) {
    Promise.nfapply(testNodeObject.test.bind(testNodeObject), ['123', '789'])
      .then(function(resolve) {
        expect(resolve).toBe('123456789');
        done();
      })
      .catch(function() {
        throw Error('should never run');
      });
  });

  it("should reject nfapply objects that callback with an error", function(done) {
    Promise.nfapply(testNodeObject.testFailure.bind(testNodeObject), ['123', '789'])
      .then(function(resolve) {
        throw Error('should never run');
      })
      .catch(function() {
        done();
      });
  });

  // -- denodify

  it("denodify should generate node function calls wrapped with promises that dont callback with an error", function(done) {
    Promise.denodify(testNodeObject.test.bind(testNodeObject))('123', '')
      .then(function(resolve) {
        expect(resolve).toBe('123456');
        done();
      })
      .catch(function() {
        throw Error('should never run');
      });
  });

  it("denodify should generate node function calls wrapped with promises that callback with an error", function(done) {
    Promise.denodify(testNodeObject.testFailure.bind(testNodeObject))('123', '')
      .then(function(resolve) {
        throw Error('should never run');
      })
      .catch(function() {
        done();
      });
  });

  // -- fcall

  it("fcall should work", function(done) {
    Promise
      .fcall(function() {
        return 123;
      })
      .then(function(value) {
        expect(value).toBe(123);
        return Promise.fcall(function() { return Promise.resolve(456) });
      })
      .catch(function(e) {
        throw Error('should never run');
      })
      .then(function(value) {
        expect(value).toBe(456);
        return Promise.fcall(function() { asdasd });
      })
      .catch(function() {
        done();
      })
  });

  it("fcall should reject", function(done) {
    Promise
      .fcall(function() {
        return Promise.reject(123);
      })
      .catch(function() {
        done();
      })
  });

  // -- all() should work

  it("all() should reject", function(done) {
    Promise
      .fcall(function() {
        return [1,2,3,4,5];
      })
      .all()
      .spread(function(a,b,c,d,e,f,g) {
        expect(a).toBe(1);
        expect(b).toBe(2);
        expect(c).toBe(3);
        expect(d).toBe(4);
        expect(e).toBe(5);
        done();
      })
      .catch(function() {
        throw Error('should never run');
      })
  });

  // -- makeNodeResolver() should work

  it("makeNodeResolver() should resolve", function(done) {
    var deferred = Promise.defer();
    testNodeObject.test('123', '', deferred.makeNodeResolver());
    deferred.promise
      .then(function(resolve) {
        expect(resolve).toBe('123456');
        done();
      })
      .catch(function() {
        throw Error('should never run');
      });
  });

  it("makeNodeResolver() should reject", function(done) {
    var deferred = Promise.defer();
    testNodeObject.testFailure('123', '', deferred.makeNodeResolver());
    deferred.promise
      .then(function(resolve) {
        throw Error('should never run');
      })
      .catch(function() {
        done()
      });
  });

  // -- $promise should work

  it("$promise should resolve", function(done) {
    testNodeObject.$promise('test', '123', '')
      .then(function(resolve) {
        expect(resolve).toBe('123456');
        done();
      })
      .catch(function() {
        throw Error('should never run');
      });
  });

  it("$promise should reject", function(done) {
    testNodeObject.$promise('testFailure', '123', '')
      .then(function(resolve) {
        throw Error('should never run');
      })
      .catch(function() {
        done()
      });
  });



});