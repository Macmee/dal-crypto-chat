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
}]);

server.start(error => {
	if (error) throw error;
  console.log('Server running at:', server.info.uri);
});
