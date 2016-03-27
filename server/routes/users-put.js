import Joi from 'joi';
import UserModel from '../models/UserModel';
import Promise from 'enhanced-promises';

const user_is_valid = (username, public_key) => {
  return UserModel
    .findOne({
      $or: [
        { username },
        { public_key }
      ]
    })
    .then(user => {
      return Promise.resolve(!user && username.length >= 1 && public_key.length > 350);
    });
};

export default {
  validate: { 
    payload: { 
      username: Joi.string().required(),
      public_key: Joi.string().required()
    }
  },
  handler: function (req, reply) {
  	const params = req.payload;
    user_is_valid(params.username, params.public_key)
      .then(is_valid => {
        if (!is_valid) {
          return false;
        }
        return new UserModel({
  		    username: params.username,
  		    public_key: params.public_key
  	    }).save();
      })
      .then(user => {
        reply({ success: !!user }).code(200);
      })
      .catch(error => {
        console.log(error, error.stack);
        reply({ reason: 'failed saving in NeDB' }).code(500);
      });
  }
};
