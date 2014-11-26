class User
    constructor: (@id, @name, @room) ->
        @joined_time = new Date()

    setRoomId: (id) ->
        @room = id

    getRoomId: () ->
        @room

    setName: (name) ->
        @name = name

class Users
    constructor: () ->
        @users = {}
        @length = 0

    get: (id) ->
        @users[id]

    add: (id, name, room) ->
        @length++ unless @users[id]
        user = new User(id, name, room)
        @users[id] = user
        return user

    remove: (id) ->
        @length-- if @users[id]
        delete @users[id]

    find: (ids) ->
        results = []
        for own id, user of @users
            results.push(user) if id in ids
        return results

    sortByTime: (users) ->
        users.sort((a, b)->
            (new Date(a)).getTime() - (new Date(b)).getTime()
        )
        return users

module.exports = Users
