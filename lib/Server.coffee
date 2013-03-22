defaultAdapter = require './adapter'
operations = require './operations'
async = require 'async'
Vein = require 'vein'
{EventEmitter} = require 'events'

class Server extends EventEmitter
  constructor: (@httpServer, @options={}) ->
    @options.debug ?= false
    @options.presence ?= true
    @options.namespace ?= "holla"

    @vein = Vein.createServer @httpServer, @options
    @vein.add(k, v.bind(@)) for k,v of operations

    # make adapter
    @adapter = vein: @vein
    for k,v of defaultAdapter
      if typeof v is "function"
        @adapter[k]=v.bind @adapter
      else
        @adapter[k]=v

    if @options.adapter
      for k,v of @options.adapter
        if typeof v is "function"
          @adapter[k]=v.bind @adapter
        else
          @adapter[k]=v

    # handle presence stuff
    if @options.presence
      @on 'register', (req) =>
        @updatePresence
          name: req.socket.identity
          socket: req.socket
          online: true

      @on 'unregister', (req) =>
        @updatePresence
          name: req.socket.identity
          socket: req.socket
          online: false

  updatePresence: (preq, cb) ->
    @adapter.getPresenceTargets preq, (err, receivers) =>
      return cb? err if err?
      send = (id, done) =>
        @adapter.sendMessage id,
          type: "presence"
          args:
            name: preq.name
            online: preq.online
        , done

      async.forEach receivers, send, cb
      return

module.exports = Server