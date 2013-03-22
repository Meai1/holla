Call = require './Call'
shims = require './shims'
Vein = require 'vein'
recorder = require 'recorder'
Emitter = require 'emitter'

class Client extends Emitter
  constructor: (@options={}) ->
    @options.namespace ?= "holla"
    @options.debug ?= false
    @options.presence ?= true
    @vein = Vein.createClient @options
    @vein.ready (services) =>
      console.log services

    @vein.on "invalid", (socket, msg) =>
      @handleMessage socket, msg

  register: (name, cb) ->
    @vein.ready =>
      @vein.register name, (err) =>
        return cb err if err?
        @registered = true
        @emit "registered"
        cb()

  call: (user) -> new Call @, user, true

  chat: (user, msg) ->
    @vein.ready =>
      @vein.chat user, msg
    return @

  ready: (fn) ->
    if @registered
      fn()
    else
      @once 'registered', fn
    return @

  handleMessage: (socket, msg) ->
    console.log msg if @options.debug
    switch msg.type
      when "offer"
        c = new Call @, msg.from, false
        @emit "call", c

      when "presence"
        @emit "presence", msg.args
        @emit "presence.#{msg.args.name}", msg.args.online

      when "chat"
        @emit "chat", {from: msg.from, message: msg.args.message}
        @emit "chat.#{msg.from}", msg.args.message

      when "hangup"
        @emit "hangup", {from: msg.from}
        @emit "hangup.#{msg.from}"

      when "answer"
        @emit "answer", {from: msg.from, accepted: msg.args.accepted}
        @emit "answer.#{msg.from}", msg.args.accepted

      when "candidate"
        @emit "candidate", {from: msg.from, candidate: msg.args.candidate}
        @emit "candidate.#{msg.from}", msg.args.candidate

      when "sdp"
        @emit "sdp", {from: msg.from, sdp: msg.args.sdp, type: msg.args.type}
        @emit "sdp.#{msg.from}", msg.args

holla =
  createClient: (opt) -> new Client opt
  Client: Client
  Call: Call
  supported: shims.supported
  config: shims.PeerConnConfig
  streamToBlob: (s) -> shims.URL.createObjectURL s
  pipe: (stream, el) ->
    uri = holla.streamToBlob stream
    shims.attachStream uri, el

  record: recorder
  
  createStream: (opt, cb) ->
    return cb "Missing getUserMedia" unless shims.getUserMedia?
    err = cb
    succ = (s) -> cb null, s
    shims.getUserMedia opt, succ, err
    return holla

  createFullStream: (cb) -> holla.createStream {video:true,audio:true}, cb
  createVideoStream: (cb) -> holla.createStream {video:true,audio:false}, cb
  createAudioStream: (cb) -> holla.createStream {video:false,audio:true}, cb

module.exports = holla