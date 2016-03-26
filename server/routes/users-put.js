import Joi from 'joi';
import UserModel from '../models/UserModel';

export default {
  validate: { 
    query: { 
      username: Joi.string().required(),
      public_key: Joi.string().required()
    }
  },
  handler: function (req, reply) {
  	const params = req.payload;
  	const user = new UserModel({
  		username: params.username,
  		public_key: params.public_key
  	});
    user
      .save()
      .then(() => reply({ success: true }).code(200))
      .catch(error => {
        console.log(error, error.stack);
        reply({ reason: 'failed saving in NeDB' }).code(500);
      });
  }
};
