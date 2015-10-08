var app = require('express')();
var http = require('http').Server(app);
var io = require('socket.io')(http);

app.get('/', function(req, res){
  res.sendFile(__dirname + '/index.html');
});

io.on('connection', function(socket){
  socket.on('username', function(name) {
  	socket.username = name;
  	io.emit('user joined', socket.username);
  });
  socket.on('chat message', function(msg){
    io.emit('chat message', socket.username, msg);
  });
  socket.on('typing', function() { 
  	io.emit('isTyping', socket.username);
  });
  socket.on('stop typing', function () {
  	io.emit('isNotTyping', socket.username);
  });
  socket.on('disconnect', function () {
    io.emit('user left', socket.username);
  });
});

http.listen(8080, function(){
  console.log('listening on *:8080');
});