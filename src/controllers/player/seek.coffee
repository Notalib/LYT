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
      @_run =>
        @seekAttemptCount = 0
        # Ensure that offset has a useful value
        # Fixing odd buffer bug in Chrome 24 where offset == 0 causes it to stop buffering
        offset = @offset
        offset = 0.000001 if offset == 0
        @seek()

  seek: ->
    if ++@seekAttemptCount < 3
      @el.jPlayer 'pause', @offset
    else
      @reject 'Failed to seek after reaching attempt limit'

  handles: ->
    seeked: (event) =>
      if -0.1 < @offset - event.jPlayer.status.currentTime < 0.1
        @resolve event.jPlayer.status
      else
        @seek()

    # IOS will some times omit seeking (both the actual seek and the
    # following seeked event are missing) and just start playing from
    # the start of the stream. We detect this here and do another seek
    # if it is the case.
    stalled: (event) => @seek()
