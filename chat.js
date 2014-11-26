var app = require('express')();
var http = require('http').Server(app);
var io = require('socket.io')(http);

var users = {
	/* socketId: {
		name: username
		roomId: roomId
	}
	*/
};

var rooms = {
	/*
	* uniqueId: [<userId>]
	* }
	* */
};

app.get('/', function(req, res){
	res.sendFile(__dirname + '/index.html');
});

io.on('connection', function(socket){
	console.log('connected');
	users[socket.id] = {
		name: '',
		room: ''
	};

	socket.on('sendMessage', function (data) {
		console.log('send chat', data);
		io.sockets.to(data.room).emit('message', data)
	});

	socket.on('disconnect', function() {

		var user = users[socket.id];
		rooms[user.room].remove(socket.id);
		if (rooms[user.room].length === 0) {
			delete rooms[user.room]
		}
		delete users[socket.id];
		try {
			io.sockets.to(user.room).emit('disconnected', user);
		}
		catch (e) {
			console.error(e)
		}
		console.log('disconnect', users, socket.id, rooms);
	});

	socket.on('join', function (data) {
		createRoom(socket, data)
	});


});

/*
* @param data {Object}
* @option data {String} room
* @option data {String} username
* */
function createRoom (socket, data) {
	socket.join(data.room, function (err) {

		if (err) {
			console.error(error);
			return
		}
		users[socket.id] = {name: data.username, room: data.room};
		if (!rooms[data.room]) {rooms[data.room] = [];}
		rooms[data.room].push(socket.id);
		io.sockets.to(data.room).emit('joined', data);
		console.log('joined', data, users, socket.id, rooms);
	});
}

http.listen(3000, function(){
	console.log('listening on *:3000');
});



Array.prototype.remove = function(item) {
	var index = this.indexOf(item);
	this.splice(index, 1);
	return this;
};
