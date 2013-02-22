# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.play extends LYT.player.command

  constructor: (el) ->
    super el
    @_run =>
      @el.jPlayer 'play'

  cancel: -> @el.jPlayer 'pause'

  handles: ->
    playing: (event) =>
      @notify event.jPlayer.status

    timeupdate: (event) =>
      @notify event.jPlayer.status

    ended: (event) =>
      @resolve event.jPlayer.status

    pause: (event) =>
      @reject event.jPlayer.status
