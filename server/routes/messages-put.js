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
  handler: function (req, res) {
  	const params = req.payload;
  	const message = new MessageModel({
  		user_id: params.user_id,
  		to_user_id: params.to_user_id,
  		message: params.message
  	});
    message
      .save()
      .then(() => { console.log(12); res.json(200, { success: true }) })
      .then(() => res.json(500, { reason: 'failed saving in NeDB' }));
  }
};