app = require("express")()
http = require("http").Server(app)
io = require("socket.io")(http)
path = require 'path'
Flat = require './flat'
Users = require './users'


# socketId: {
#		name: username
#		roomId: roomId
#	}
#	
users = new Users
#
#	* uniqueId: [<userId>]
#	* }
#	* 

rooms = {}

flat = new Flat

app.get "/", (req, res) ->
    res.sendFile path.join(__dirname, "../index.html")
    return

io.on "connection", (socket) ->
    console.log "connected", socket.id

    users.add(socket.id, "", "")

    socket.on "sendMessage", (data) ->

        user = users.get(socket.id)
        room = user.getRoomId()
        console.log "send chat", data, user.id, room
        data.author = user
        data.date = new Date()
        io.sockets.to(room).emit("message", data) if room

    socket.on "disconnect", ->
        user = users.get(socket.id)
        room = user.getRoomId()
        flat.removeUser(room, user.id)
        users.remove(user.id)

        try
            io.sockets.to(room).emit "disconnected", user
        catch e
            console.error e
        console.log "disconnect", users, socket.id, rooms

    socket.on "join", (data) ->
        namespace = data.room
        socket.join namespace, (err) ->
            if err
                console.error err
                return
            user = users.add(socket.id, data.username, namespace)
            flat.push(namespace).addUser(user.id)
            usersInFlat = users.find(flat.get(namespace).getUsers())
            data =
                users: usersInFlat
                me: user
                room: namespace

            socket.emit("joined", data)
            io.sockets.to(namespace).emit("joinedUser", user)

            firstUserInFlat = users.sortByTime(usersInFlat)[0]
            if firstUserInFlat.id isnt user.id
                firstUserSocket = io.sockets.connected[firstUserInFlat.id]
                firstUserSocket.once 'oldMessages', (data) ->
                    socket.emit "oldMessages", data
                firstUserSocket.emit "getOldMessages"


            console.log "joined", user.name, namespace, users.length, socket.id

http.listen 3000, ->
    console.log "listening on *:3000"
