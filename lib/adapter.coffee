module.exports =
  users: {}
  register: (req, cb) ->
    @users[req.name] = req.socket.id
    req.socket.identity = req.name
    cb()

  unregister: (req, cb) ->
    delete @users[req.name]
    cb()

  getId: (name, cb) ->
    cb null, @users[name]

  getPresenceTargets: (req, cb) ->
    cb null, (id for user, id of @users when user isnt req.name)

  sendMessage: (id, msg, cb) ->
    return cb "Invalid client" unless @vein.server.clients[id]?
    @vein.clients[id].write msg
    cb()