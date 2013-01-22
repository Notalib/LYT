# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.play extends LYT.player.command

  constructor: (el, @callback) ->
    super el
    @_run =>
      @el.jPlayer 'play'

  handles:
    playing: (event) =>
      this.resolve event.jPlayer.status

    timeupdate: (event) =>
      @callback event.jPlayer.status
