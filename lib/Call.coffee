shims = require './shims'

EventEmitter = require 'emitter'

class Call extends EventEmitter
  constructor: (@parent, @user, @isCaller) ->
    @pc = @createConnection()
    @vein = @parent.vein

    if @isCaller
      @vein.ready =>
        @vein.offer @user, (err) =>
          return @emit 'error', err if err?
          @emit "calling"

    @parent.on "answer.#{@user}", (accepted) =>
      return @emit "rejected" unless accepted
      @startTime = new Date
      @emit "answered"
      @initSDP()

    @parent.on "candidate.#{@user}", (candidate) =>
      @pc.addIceCandidate new shims.IceCandidate candidate

    @parent.on "sdp.#{@user}", (desc) =>
      desc.sdp = shims.processSDPIn desc.sdp
      err = (e) -> throw e
      succ = =>
        @initSDP() unless @isCaller
        @emit "sdp"
      @pc.setRemoteDescription new shims.SessionDescription(desc), succ, err

    @parent.on "hangup.#{@user}", =>
      @emit "hangup"

    @parent.on "chat.#{@user}", (msg) =>
      @emit "chat", msg

  createConnection: ->
    pc = new shims.PeerConnection shims.PeerConnConfig, shims.constraints
    pc.onconnecting = =>
      @emit 'connecting'
      return
    pc.onopen = =>
      @emit 'connected'
      return
    pc.onicecandidate = (evt) =>
      if evt.candidate
        @parent.vein.ready =>
          @parent.vein.candidate @user, evt.candidate
      return

    pc.onaddstream = (evt) =>
      @remoteStream = evt.stream
      @_ready = true
      @emit "ready", @remoteStream
      return
    pc.onremovestream = (evt) =>
      console.log "removestream", evt
      return

    return pc

  addStream: (s) ->
    @localStream = s
    @pc.addStream s
    return @

  ready: (fn) ->
    if @_ready
      fn @remoteStream
    else
      @once 'ready', fn
    return @

  duration: ->
    s = @endTime.getTime() if @endTime?
    s ?= Date.now()
    e = @startTime.getTime()
    return (s-e)/1000

  chat: (msg) ->
    @parent.chat @user, msg
    return @

  answer: ->
    @startTime = new Date
    @parent.vein.ready =>
      @parent.vein.answer @user, true
    return @

  decline: ->
    @parent.vein.ready =>
      @parent.vein.answer @user, false
    return @

  end: ->
    @endTime = new Date
    try
      @pc.close()
    @parent.vein.ready =>
      @parent.vein.hangup @user
    @emit "hangup"
    return @

  initSDP: ->
    done = (desc) =>
      desc.sdp = shims.processSDPOut desc.sdp
      @pc.setLocalDescription desc
      @parent.vein.ready =>
        @parent.vein.sdp @user, desc

    err = (e) -> throw e

    return @pc.createOffer done, err, shims.constraints if @isCaller
    return @pc.createAnswer done, err, shims.constraints if @pc.remoteDescription
    @once "sdp", =>
      @pc.createAnswer done, err

module.exports = Call