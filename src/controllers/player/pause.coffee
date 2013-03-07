# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.pause extends LYT.player.command

  constructor: (el) ->
    super el
    @_run =>
      @el.jPlayer 'play'

  handles: ->
    timeupdate: (event) =>
      if event.jPlayer.status.paused
        this.resolve event.jPlayer.status
