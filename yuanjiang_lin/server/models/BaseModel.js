import Nedb from 'nedb';
import Backbone from 'backbone';
import _ from 'underscore';
import Promise from 'enhanced-promises';

/**
 * instead of doing ugly queries like model.find({ $lte: { created_at: new Date } })
 * we can do model.find({ created_at: (new Date).lte })
 */
var comparators = ['lt','lte','gt','gte','ne','nin','in'];
var applyTo = [String, Number, Boolean, Array];
comparators.forEach(function(c) {
  for(var i in applyTo) {
    var obj = applyTo[i];
    Object.defineProperty(obj.prototype, c, {
      enumerable: false,
      configurable: false,
      get: function() {
        var obj = {};
        obj['$'+c] = this;
        return obj;
      }
    });
  }    
});

/**
 * for cases when user doesnt specify nodejs callback, builds the appropriate
 * promise. Also calculates `chainValue` which can be returned from
 * the function to continue chaining (as specified for callback
 * or promise chaining otherwise)
 * @param {Object} defaultChainValue the default chaining value for when we have a callback
 * @return {Object} (optional) callback if specified, THIS is returned with `chainValue` prop as `defaultChainValue`, callback with a promise is generated (along with a generated chainValue) otherwise.
 */

var promiseFallback = function(defaultChainValue, callback) {
  var deferred;
  if (callback !== undefined) {
    callback.chainValue = defaultChainValue;
  } else {
      deferred = Promise.defer();
      callback = function(err, data) {
        if (err) {
          deferred.reject(err);
        } else {
          deferred.resolve(data);
        }
      };
    callback.chainValue = deferred.promise;
  }
  return callback;
};

var openDBs = {};

var BaseModel = Backbone.Model.extend({

  /**
   * asyncronously persist the model to the local database
   * @param {Function} callback runs when complete
   */
  
  save: function(callback) {
    // if no callback is given, return a promise
    callback = promiseFallback(this, callback);
    var attrs = this.attributes;
    // update
    if(attrs._id) {
      var id = attrs._id;
      if(attrs.id != attrs._id) {
        attrs._id = attrs.id;
      }
      if(this.neDBoptions.timestamps) {
        this.set('updated_at', new Date);
      }
      delete attrs.id;
      this.neDB.update({ _id: id }, attrs, {}, callback);
      attrs.id = id;
      // insert
    }else{
      if(this.neDBoptions.timestamps) {
        this.set('created_at', new Date);
      }
      attrs._id = this.neDB.createNewId();
      this.set('id', attrs._id);
      this.neDB.insert(attrs, callback);
    }
    return callback.chainValue;
  },

  /**
   * asyncronously delete the model from the database
   * @param {Function} callback runs when complete
   */

  remove: function(callback) {
    if(this.attributes._id) {
      callback = promiseFallback(this, callback);
      this.neDB.remove({ _id: this.attributes._id }, {}, callback);
      delete this.attributes._id;
      delete this.attributes.id;
    }
    return callback.chainValue;
  }

});

/**
 * Takes hash of data and maps it to the Backbone model, assigns id from _id and returns
 * @param {Object} data The hashmap being returned
 * @return {Backbone.Model} model representation of data provided, with correct id
 */

BaseModel.mapDataToSelf = function(data) {
  if(!data) return undefined;
  var obj = new this;
  obj.attributes = data;
  obj.attributes.id = data._id;
  return obj;
};

/**
 * assigns a collection name to the model and creates Nedb instance for the model
 * @param {String} name the name of the collection that we're mapping the model to
 * @param {Object} options
 *                 options.timestamps - (default: true) automatically maintain created_at and updated_at
 */

var defaultOptions = { timestamps: true, autoload: true };
BaseModel.setCollection = function(name, options) {
  this.prototype.neDBoptions = _.extend(defaultOptions, options || {});
  var db = openDBs[name];
  if(!db) {
    db = openDBs[name] = new Nedb({ filename: name, autoload: this.prototype.neDBoptions.autoload });
  }
  this.prototype.neDB = db;
};

/**
 * this structure keeps track of functions that were called on our query
 * results and stores them until we have the results
 * @param {Object} query a neDb compliant query
 * @param {Object} model a backbone compliant model
 * @param {Object} mode (default find) either find or count
 */

function QueryBuilder(query, model, mode) {
  if(!mode) mode = 'find';
  this.actions = [];
  this.model = model;
  if (model.prototype.neDB === undefined) {
    throw new Error('you forgot to call setCollection on your model, do '
                    + 'yourModel.setCollection("path/to/where/you/want/to/store/your/db/here")');
  }
  this.query = model.prototype.neDB[mode](query);
}

QueryBuilder.prototype.perform = function() {
  if(this.performed) return;
  this.performed = true;
  var self = this;
  this.query.exec(function(err, data) {
    if(typeof data == 'number') data = [data]; // used for count queries
    new QueryHandler(err, data, self.actions, self.model);
  });
};

QueryBuilder.prototype.exec = function(callback) {
  // if no callback is given, return a promise
  callback = promiseFallback(this, callback);
  // push the callback on the queue and perform the query
  console.log('b', this.actions.length);
  this.actions.push(['exec',callback]);
    console.log('bc', this.actions.length);
  this.perform();
  return callback.chainValue;
};

QueryBuilder.prototype.then = function(callback) {
  var promise = this.exec();
  return promise.then.apply(promise, arguments);
};

QueryBuilder.prototype.forEach = function(enumerator) {
  this.actions.push(['forEach',enumerator]);
  this.perform();
  return this;
};

QueryBuilder.prototype.error = function(callback) {
  this.actions.push(['error',callback]);
  return this;
};

QueryBuilder.prototype.asc = function(key) {
  this.query = this.query.sort({ key: 1 });
  return this;
};

QueryBuilder.prototype.desc = function(key) {
  this.query = this.query.sort({ key: -1 });
  return this;
};

QueryBuilder.prototype.sort = function(sort) {
  this.query = this.query.sort(sort);
  return this;
};

QueryBuilder.prototype.limit = function(limit) {
  this.query = this.query.limit(limit);
  return this;
};

QueryBuilder.prototype.skip = function(skip) {
  this.skip = this.query.skip(skip);
  return this;
};

/**
 * this class takes a QueryBuilder along with query results and a
 * model, and performs the functions stored in Queue
 * @param {Object} err database error if one occured, otherwise undefined
 * @param {Array} data array of objects which will be mapped to the model
 * @param {Object} actions array of [actionString, Function] that we want to perform on the data fetched from the db
 * @param {Backbone.Model} model the backbone model in which we're mapping array of data to
 */

function QueryHandler(err, data, actions, model) {
  this.data = data || [];
  this.model = model;
  this.err = err;
  for(var i in actions) {
    var op = actions[i];
    var action = op[0];
    var enumerator = op[1];
    if (this[action]) {
      this[action](enumerator);
    } else {
      throw Error('BaseModel cant find action ' + action + ' in QueryHandler');
    }
  }
}

/**
 * When the user performs someModel.find({}).forAll(arrayOfModels), this is the method which will eventually run
 * @param {Function} enumerator a the callback we are running within forAll
 */

QueryHandler.prototype.exec = function(callback) {
  var data = this.data;
  // the database returned just a single number, it must be a count
  if(data.length == 1 && typeof data[0] == 'number') {
    return callback(this.err, data[0]);
  }
  var model = this.model;
  var array = [];
  for(var i in data) {
    var obj = model.mapDataToSelf(data[i]);
    array.push(obj);
  }
  return callback(this.err, array);
};

/**
 * When the user performs someModel.find({}).forEach(..), this is the method which will eventually run
 * @param {Function} enumerator a the enumerator we are running within forEach
 */

QueryHandler.prototype.forEach = function(enumerator) {
  var data = this.data;
  var model = this.model;
  for(var i in data) {
    var obj = model.mapDataToSelf(data[i]);
    enumerator(obj, i);
  }
};

/**
 * Perform Nedb find query and return a QueryBuilder
 * @param {Object} query a properly formatted NeDB query or string representing an id
 * @param {Function} callback optional if provided, will perform forEach on after query completes
 * @return {QueryBuilder} QueryBuilder, which you can call forEach, skip, limit, sort, asc, desc, exec, on
 */

BaseModel.find = function(query, callback) {
  if(typeof query == 'string') {
    query = { _id: query };
  }
  var queryBuilder = new QueryBuilder(query, this);
  if(callback) {
    queryBuilder.exec(callback);
  }
  return queryBuilder;
};

/**
 * Perform Nedb count query and return a QueueBuilder
 * @param {Object} query a properly formatted NeDB query or string representing an id
 * @param {Function} callback optional if provided, will perform forEach on after query completes
 * @return {QueryBuilder} QueryBuilder, which you can call forEach, skip, limit, sort, asc, desc, exec, on
 */

BaseModel.count = function(query, callback) {
  if(typeof query == 'string') {
    query = { _id: query };
  }
  var queryBuilder = new QueryBuilder(query, this, 'count');
  if(callback) {
    queryBuilder.exec(callback);
  }
  return queryBuilder;
};

/**
 * Perform Nedb findOne query
 * @param {Object} query a properly formatted NeDB query or string representing an id
 * @param {Function} callback to be performed after findOne is complete
 */

BaseModel.findOne = function(query, callback) {
  callback = promiseFallback(this, callback);
  this.find(query).limit(1).exec(function(err, items) {
    callback(err, items.length > 0 ? items[0] : null);
  });
  return callback.chainValue;
};

/*var someModel = BaseModel.extend({ name: '', color: '' });
 someModel.setCollection('someModel');

 var someOtherModel = someModel.extend({ phone: ''});
 someOtherModel.setCollection('someOtherModel');

 someModel.find({}).exec(function(err,d){ window.a = d });

 y = new someModel; y.set('bob', 6); y.save();
 someModel.find({ bob: 6 }).forEach(function(d){ console.log(d) });*/

export default BaseModel;
