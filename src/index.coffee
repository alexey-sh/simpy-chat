express = require("express")
app = express()
http = require("http").Server(app)
io = require("socket.io")(http)
path = require 'path'
Flat = require './flat'
Users = require './users'
cookieParser = require 'cookie-parser'
i18n = require 'i18n'
ejs = require 'ejs'

port = process.env.PORT or 3000


users = new Users
flat = new Flat

locales = ['en', 'ru']

i18n.configure
    locales: locales,
    cookie: 'lang',
    defaultLocale: 'en',
    directory: path.join(__dirname, '../locales')

app.use(cookieParser())
app.use(i18n.init)
app.set('views',  path.join(__dirname, '../views'))
app.set('view engine', 'ejs');
app.use(express.static(path.join(__dirname, '../favicons'), { maxAge: 1e+20}));

app.get "/", (req, res) ->
    locale = res.getLocale()
    res.redirect("/#{locale}/")

app.get "/:locale/", (req, res) ->
    res.setLocale(req.params.locale)
    res.cookie('lang', res.getLocale());
    res.render('index',
        i18n: res.__
        locales: locales
        httpURL: "https://#{req.get('host')}#{req.originalUrl}"
    )
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
        console.log "disconnect", users, socket.id

    socket.on "join", (data) ->
        namespace = data.room
        existsRoom = flat.get(namespace)
        if existsRoom
            if data.verification isnt existsRoom.verification
                console.log('verification failed', data.verification, existsRoom.verification)
                socket.emit('joinFailed')
                return
            else
                console.log('verified successfully')
        console.log('join user to namespace', data.username, namespace)
        socket.join namespace, (err) ->
            if err
                console.error err
                return
            user = users.add(socket.id, data.username, namespace)
            flat.push(namespace, data.verification).addUser(user.id)
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

http.listen port , ->
    console.log "listening on *:#{port}"
