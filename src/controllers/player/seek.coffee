# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.seek extends LYT.player.command

  constructor: (el, @offset) ->
    super el
    # Don't check against upper bound if duration is unavailable
    # This happens on IOS during first play as well as when it has been
    # impossible to get metadata.
    # jPlayer sets duration to 0 in stead of NaN when duration is unavailable?!
    if @offset < 0 or @status.duration and @offset > @status.duration + 0.1
      this.reject "Offset #{@offset} is out of bounds"
    else
      @src = @status().src
      @always => clearInterval @seekInterval
      @_run =>
        # Ensure that offset has a useful value
        # Fixing odd buffer bug in Chrome 24 where offset == 0 causes it to stop buffering
        offset = @offset
        offset = 0.000001 if offset == 0
        @seekAttempts = 0
        # Chrome chokes if the seek command is sent too fast after a load 
        # This is handled by retrying the seek until it works
        # TODO: [play-controllers] find out if there is a more elegant way
        #       to avoid this - maybe by having the load command wait for
        #       the player to get into a seekable state.
        @seekInterval = setInterval(
          => @seek()
          100
        )

  seek: ->
    # TODO: Configurable number of seek attempts
    if ++@seekAttempts < 10
      log.message "Seek command #{@id} trying to seek to #{@offset} in #{@src}"
      @el.jPlayer 'pause', @offset
    else
      @reject 'Failed to seek after reaching attempt limit'

  handles: ->
    seeked: (event) =>
      return unless event.jPlayer.status.src is @src
      if -0.1 < @offset - event.jPlayer.status.currentTime < 0.1
        @resolve event.jPlayer.status
      else
        @seek()

    # IOS will some times omit seeking (both the actual seek and the
    # following seeked event are missing) and just start playing from
    # the start of the stream. We detect this here and do another seek
    # if it is the case.
    stalled: (event) =>
      return unless event.jPlayer.status.src is @src
      @seek()
      
    seeking: (event) =>
      clearInterval @seekInterval
