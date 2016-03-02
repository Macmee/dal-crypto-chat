import Hapi from 'hapi';

const server = new Hapi.Server();
server.connection({ 
  host: '0.0.0.0', 
  port: 8000 
});

server.route([{
  method: 'PUT',
  path:'/messages',
  config: require('./routes/messages-put')
}]);

server.start(error => {
	if (error) throw error;
  console.log('Server running at:', server.info.uri);
});