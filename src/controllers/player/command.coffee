# Requires `/controllers/player`

class LYT.player.command extends jQuery.Deferred
  constructor: (@el) ->
    jQuery.extend this, jQuery.Deferred()
    
  attach: ->
    for name, handler of @handles
      @el.on $.jPlayer.event[name], handler

  detach: ->
    for name, handler of @handles
      @el.unbind $.jPlayer.event[name], handler

  _run: (callback) ->
    this.always => @detach()
    @attach()
    callback() if @state() is 'pending'

  cancel: ->

  handles: {}

  status: => @el.data('jPlayer').status
