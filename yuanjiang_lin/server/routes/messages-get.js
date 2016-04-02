import Joi from 'joi';
import MessageModel from '../models/MessageModel';

export default {
  validate: { 
    query: { 
      user_id: Joi.string().required(),
    }
  },
  handler: function (req, reply) {
    MessageModel
      .find({ to_user_id: req.query.user_id })
      .then(messages => reply({ messages }).code(200))
      .catch(error => {
        console.log(error, error.stack);
        reply({ reason: 'failed fetching in NeDB' }).code(500);
      });
  }
};
