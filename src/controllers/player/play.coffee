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

  cancel: ->
    super()
    @el.jPlayer 'pause'
    @_stop()

  _stop: ->
    if @cancelled
      @reject()
    else
      @resolve()

  handles: ->
    playing: (event) =>
      @playing = true
      @notify event.jPlayer.status

    timeupdate: (event) =>
      if @playing and (event.jPlayer.status.paused or @cancelled)
        @_stop()
      else
        @notify event.jPlayer.status

    ended: (event) => @_stop()

    pause: (event) => @_stop()

