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
    @audio = @el.find('audio')[0]
    @_run =>
      if @audio.readyState is 4
        # If we've got the canplaythrough event, we just play
        @el.jPlayer 'play'
      else
        # Otherwise we apply a different strategy, by waiting a couple of
        # seconds, but still ensuring responsivenes
        @firstplay = true
        @el.jPlayer 'play'
        setTimeout(
          => @el.jPlayer 'pause'
          200
        )
        setTimeout(
          =>
            @firstplay = false
            @el.jPlayer 'play'
          4000
        )

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
    canplaythrough: (event) =>
      log.message "Command play: Received canplaythrough event"

    playing: (event) =>
      return if @firstplay
      log.message "Command play: Now playing audio"
      @playing = true
      @notify event.jPlayer.status

    timeupdate: (event) =>
      @notify event.jPlayer.status

    ended: (event) =>
      log.message "Command play: Audio playing ended"
      @_stop()

    pause: (event) =>
      log.message "Command play: paused due to buffering"

