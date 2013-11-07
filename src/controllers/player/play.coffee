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
    # @justCancelled is introduced because we (for whatever reason) still receive
    # "timeupdate" events after having paused the jPlayer element. We use this
    # to "soak up" any "timeupdate" events after pause, so we don't mess up
    # the play() method in the player
    # # @justCancelled is introduced because we (for whatever reason) still receive
    # "timeupdate" events after having paused the jPlayer element. We use this
    # to "soak up" any "timeupdate" events after pause, so we don't mess up
    # the play() method in the player
    @justCancelled = true

  _stop: (event) ->
    method = if @cancelled then @reject else @resolve
    method.apply this, event.jPlayer.status

  handles: ->
    playing: (event) =>
      @playing = true
      @notify event.jPlayer.status

    timeupdate: (event) =>
      if @playing and (event.jPlayer.status.paused or @justCancelled)
        @_stop event
      else
        @notify event.jPlayer.status

    ended: (event) => @_stop event

    pause: (event) => @_stop event

