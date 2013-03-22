module.exports =
  # misc controls
  register: (res, name) ->
    return res.reply "Missing name" unless typeof name is 'string'

    req =
      name: name
      socket: res.socket

    @adapter.register req, res.reply

  chat: (res, target, msg) ->
    return res.reply "Missing target" unless typeof target is 'string'
    return res.reply "Missing message" unless typeof msg is 'string'
    return res.reply "Not registered" unless typeof res.socket.identity is 'string'

    @adapter.getId target, (err, id) =>
      return res.reply err if err?
      return res.reply "Invalid target" unless @vein.server.clients[id]?

      @adapter.sendMessage id,
        type: "chat"
        from: res.socket.identity
        args:
          message: msg

      @emit "chat", 
        name: res.socket.identity
        socket: socket
        to: target
        message: msg

  # call controls
  offer: (res, target) ->
    return res.reply "Missing target" unless typeof target is 'string'
    return res.reply "Not registered" unless typeof res.socket.identity is 'string'

    @adapter.getId target, (err, id) =>
      return res.reply err if err?
      return res.reply "Invalid target" unless id?
      return res.reply "Invalid target" unless @vein.server.clients[id]?

      @adapter.sendMessage id,
        type: "offer"
        from: res.socket.identity
      , res.reply

      req =
        name: res.socket.identity
        socket: res.socket.identity
        to: target

      @emit "offer", req

  answer: (res, target, accepted) ->
    return res.reply "Missing target" unless typeof target is 'string'
    return res.reply "Missing response accepted" unless typeof accepted is 'boolean'
    return res.reply "Not registered" unless typeof res.socket.identity is 'string'

    @adapter.getId target, (err, id) =>
      return res.reply err if err?
      return res.reply "Invalid target" unless @vein.server.clients[id]?

      @adapter.sendMessage id,
        type: "answer"
        from: res.socket.identity
        args:
          accepted: accepted
      , res.reply

      @emit "answer",
        name: res.socket.identity
        socket: res.socket.identity
        to: target
        args:
          accepted: accepted

  hangup: (res) ->
    return res.reply "Missing target" unless typeof target is 'string'
    return res.reply "Not registered" unless typeof res.socket.identity is 'string'

    @adapter.getId target, (err, id) =>
      return res.reply err if err?
      return res.reply "Invalid target" unless @vein.server.clients[id]?

      @adapter.sendMessage id,
        type: "hangup"
        from: res.socket.identity
      , res.reply

      @emit "hangup",
        name: res.socket.identity
        socket: res.socket
        to: target

  candidate: (res, target, candidate) ->
    return res.reply "Missing target" unless typeof target is 'string'
    return res.reply "Missing candidate" unless typeof candidate is 'string'
    return res.reply "Not registered" unless typeof res.socket.identity is 'string'

    @adapter.getId target, (err, id) =>
      return res.reply err if err?
      return res.reply "Invalid target" unless @vein.server.clients[id]?

      @adapter.sendMessage id,
        type: "candidate"
        from: res.socket.identity
        args:
          candidate: candidate
      , res.reply


  sdp: (res, target, desc) ->
    return res.reply "Missing target" unless typeof target is 'string'
    return res.reply "Missing description" unless typeof desc is 'object'
    return res.reply "Missing sdp type" unless typeof desc.type is 'string'
    return res.reply "Missing sdp descriptipon" unless typeof desc.sdp is 'string'
    return res.reply "Not registered" unless typeof res.socket.identity is 'string'

    @adapter.getId target, (err, id) =>
      return res.reply err if err?
      return res.reply "Invalid target" unless @vein.server.clients[id]?

      @adapter.sendMessage id,
        type: "sdp"
        from: res.socket.identity
        args:
          sdp: desc.sdp
          type: desc.type
      , res.reply

