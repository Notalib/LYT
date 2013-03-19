# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.wait extends LYT.player.command

  constructor: (el, @handler) ->
    super el
    @_run =>

  handles: ->
    # Attach to every possible event handler that jPlayer offers
    getEventHandler = (eventName) =>
      (event) => @handler this, eventName, event.jPlayer.status
    handles = {}
    for eventName, jPlayerName of $.jPlayer.event
      handles[eventName] = getEventHandler eventName
    handles
