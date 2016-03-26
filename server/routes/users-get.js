import Joi from 'joi';
import UserModel from '../models/UserModel';

export default {
  validate: { 
    query: { 
      username: Joi.string().required(),
    }
  },
  handler: function (req, reply) {
    UserModel
      .findOne({ username: req.query.username })
      .then(user => reply({ exists: (user !== null) }))
      .catch(error => {
        console.log(error, error.stack);
        reply({ reason: 'failed fetching in NeDB' }).code(500);
      });
  }
};
