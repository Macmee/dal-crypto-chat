import Hapi from 'hapi';

const server = new Hapi.Server();
server.connection({
  host: '0.0.0.0',
  port: 8005
});

server.route([{
  method: 'PUT',
  path:'/messages',
  config: require('./routes/messages-put')
}, {
  method: 'GET',
  path:'/messages',
  config: require('./routes/messages-get')
}, {
  method: 'PUT',
  path:'/users',
  config: require('./routes/users-put')
}, {
  method: 'GET',
  path:'/users/{username}',
  config: require('./routes/users-get')
}, {
  method: 'GET',
  path:'/public-key/{key}',
  config: require('./routes/public-key-get')
}]);

server.start(error => {
	if (error) throw error;
  console.log('Server running at:', server.info.uri);
});
