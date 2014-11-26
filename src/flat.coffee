class Room
    constructor: () ->
        @users = []

    hasUser: (userId) ->
        userId in @users

    addUser: (userId) ->
        if not @hasUser(userId)
            @users.push(userId)

    removeUser: (userId) ->
        if @hasUser(userId)
            index = @users.indexOf(userId)
            @users.splice index, 1

    getUsers: () ->
        @users

    isEmpty: () ->
        @users.length is 0

class Flat
    constructor: () ->
        @rooms = {}

    push: (namespace) ->
        room = @rooms[namespace] or new Room()
        @rooms[namespace] = room
        return room

    get: (namespace) ->
        @rooms[namespace]

    removeUser: (namespace, userId) ->
        room = @get(namespace)
        room.removeUser(userId)
        delete @rooms[namespace] if room.isEmpty()


module.exports = Flat
