import Joi from 'joi';
import UserModel from '../models/UserModel';

export default {
  validate: { 
    params: { 
      key: Joi.string().required(),
    }
  },
  handler: function (req, reply) {
    UserModel
      .findOne({ public_key: req.params.key })
      .then(user => reply({
        exists: (user !== null),
        public_key: (user && user.get('public_key')),
        username: (user && user.get('username'))
      }))
      .catch(error => {
        console.log(error, error.stack);
        reply({ reason: 'failed fetching in NeDB' }).code(500);
      });
  }
};
