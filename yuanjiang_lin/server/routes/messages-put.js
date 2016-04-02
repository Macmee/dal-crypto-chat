import Joi from 'joi';
import MessageModel from '../models/MessageModel';

export default {
  validate: { 
    payload: { 
      user_id: Joi.string().required(),
      to_user_id: Joi.string().required(),
      message: Joi.string().required(),
    }
  },
  handler: function (req,reply) {
  	const params = req.payload;
  	const message = new MessageModel({
  		user_id: params.user_id,
  		to_user_id: params.to_user_id,
  		message: params.message
  	});
    message
      .save()
      .then(() => reply({ success: true }).code(200))
      .catch(error => {
        console.log(error, error.stack);
        reply({ reason: 'failed saving in NeDB' }).code(500);
      });
  }
};
