[![Build Status](https://travis-ci.org/Macmee/enhanced-promises.svg?branch=master)](https://travis-ci.org/Macmee/enhanced-promises)

## What is this?

As you might know, Javascript Harmony introduces native Promises. However, these Promises often lack useful functionality we are used to with other promise libraries such as Q. This library very simply adds useful methods to native Javascript promises such as `spread`, `delay`, `makeNodeResolver`, `fcall`, `all()`, `nbind`, `ninvoke`, `nfcall`, `nfapply`, `denodify`, `nbind` and `npost`.

Additionally, if native promises are not available, the library includes a very simple Promise implementation as a substitute.

## What's the point?

I wanted to use native JS Promises, I wanted `spread` and `delay` from Q, and I didn't want to special case old browsers / versions of node that don't support promises.

## How do I use this?

`npm install enhanced-promises --save` and include `require('enhanced-promises')` and carry on using `new Promise(...)` as you would before, with the added methods sprinked on top. If you're in a browser then include `enhanced-promises.min.js`

### What are Promises?

So as I said, this is a Promise library. Ideally your runtime environment already supports promises, but if not this library provides a fallback. (from firefox documentation): The Promise object is used for deferred and asynchronous computations. A Promise represents an operation that hasn't completed yet, but is expected in the future. Learn more about promises, see more about promises at https://developer.mozilla.org/en/docs/Web/JavaScript/Reference/Global_Objects/Promise

You can create promises in numerous ways, a few examples include:

```
new Promise(function(resolve, reject) {
  setTimeout(function(){ resolve(123) }, 1000);
}).then(function(value) {
  console.log(value); //123
});
```
or
```
Promise.fcall(function() {
  return 123;
}).then(function(value) {
  console.log(value); //123
});
```
or
```
Promise.resolve(123).then(function(value) {
  console.log(value); //123
});
```
or
```
Promise.reject(123).catch(function(value) {
  console.log(value); //123
});
```

### Promise.delay(ms)

returns a promise that simply delays for X ms and then resolves

```
Promise
  .delay(1000)
  .then(function() {
    console.log('this prints after 1 second');
  })
```

### Promise.fcall

You can create a promise from a value using Promise.fcall. This returns a promise for 10.

```
return Promise.fcall(function () {
    return 10;
});
You can also use fcall to get a promise for an exception.

return Promise.fcall(function () {
    throw new Error("Can't do it");
});
```

### Defer

You can use deferred objects like so:

```
var deferred = Promise.defer();
FS.readFile("foo.txt", "utf-8", function (error, text) {
    if (error) {
        deferred.reject(new Error(error));
    } else {
        deferred.resolve(text);
    }
});
return deferred.promise;
```

### Object.$promise

This is sort of adapting NodeJS but I'm giving it its own section since I think it's cool. Objects have a `$promise` method on them so that you don't ned to wrap anything around a Promise call explicitly, you can simply do:

```
Fs.$promise('readFile', 'foo.txt').then(function(text){ ... });
```

The `$promise` function is available on any object and is the easiest way to turn a non-promise function into a function that returns a promise.

### Adapting NodeJS

You can also wrap promises around nodejs functionality using:

```
Promise.nfcall(FS.readFile, "foo.txt", "utf-8").then(function(text){ ... });
Promise.nfapply(FS.readFile, ["foo.txt", "utf-8"]).then(function(text){ ... });
```

If you want to invoke a function belonging to an object without changing the value for `this` you can do:

```
Promise.ninvoke(redisClient, "get", "user:1:id");
Promise.npost(redisClient, "get", ["user:1:id"]);
```

and you can make re-usable versions of the above like so:

```
var readFile = Promise.denodeify(FS.readFile);
return readFile("foo.txt", "utf-8");

var redisClientGet = Promise.nbind(redisClient.get, redisClient);
return redisClientGet("user:1:id");
```

You can also use `makeNodeResolver`:

```
var deferred = Promise.defer();
FS.readFile("foo.txt", "utf-8", deferred.makeNodeResolver());
return deferred.promise;
```

### Spread

use as a replacement for then, if the previous promise returned an array, spread treats each element as a separate property, for example:

```
var getUsername = function() { .. returns some random promise .. }

Promise
  .all([
    123,
    Promise.resolve(456)
    getUsername()
  ])
  .spread(function(firstNumber, secondNumber, username) {
    console.log('woohoo!');
  })
```
