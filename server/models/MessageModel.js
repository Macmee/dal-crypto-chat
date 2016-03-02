import BaseModel from './BaseModel';

const MessageModel = BaseModel.extend({ });

/*TokenModel.generate = function() {
  var token = new TokenModel;
  var keypair = ed.createKeyPair(ed.createSeed());
  token.set('publicKey', keypair.publicKey.toString('base64'));
  token.set('secretKey', keypair.secretKey.toString('base64'));
  return token;
};

TokenModel.getPersonalToken = function() {
  return this.findOne({ type: 'personalToken' })
    .then(token => {
      if (token) {
        return token;
      } else {
        token = this.generate();
        token.set('type', 'personalToken');
        return token.save().then(() => token);
      }
    });
};*/

MessageModel.setCollection('db_data/MessageModel');

export default MessageModel;
