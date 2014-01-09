# Requires `/controllers/player/command`
# --------------------------------------

# ########################################################################### #
# Plays current audio file from current position to the end                   #
# ########################################################################### #

# This command will start playback of the current file at the current position
# and will only resolve once the end of file has been reached.
#
# Calling cancel() will pause playback and cause the command to reject.

class LYT.player.command.play extends LYT.player.command

  constructor: (el) ->
    super el
    @_run => @el.jPlayer 'play'
    @pollTimer = setInterval =>
      audio = @el.data('jPlayer').htmlElement.audio
      @notify currentTime: audio.currentTime, src: audio.src
    , 1000/30

  cancel: ->
    super()
    @pollTimer = clearInterval @pollTimer
    @el.jPlayer 'pause'

  _stop: (event) ->
    clearInterval @pollTimer if @pollTimer
    method = if @cancelled then @reject else @resolve
    method.apply this, event.jPlayer.status

  handles: ->
    playing: (event) =>
      @playing = true
      @notify event.jPlayer.status

    ended: (event) => @_stop event

    pause: (event) => @_stop event

