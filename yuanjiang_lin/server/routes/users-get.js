import Joi from 'joi';
import UserModel from '../models/UserModel';

export default {
  validate: { 
    params: { 
      username: Joi.string().required(),
    }
  },
  handler: function (req, reply) {
    UserModel
      .findOne({ username: req.params.username })
      .then(user => reply({
        exists: (user !== null),
        public_key: (user && user.get('public_key')),
        username: req.params.username
      }))
      .catch(error => {
        console.log(error, error.stack);
        reply({ reason: 'failed fetching in NeDB' }).code(500);
      });
  }
};
