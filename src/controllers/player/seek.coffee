# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.seek extends LYT.player.command

  constructor: (el, @offset) ->
    super el
    if @offset < 0 or @offset > @status.duration + 0.1
      this.reject "Offset #{@offset} is out of bounds"
    else
      @_run =>
        @seekAttemptCount = 0
        # Ensure that offset has a useful value
        # Fixing odd buffer bug in Chrome 24 where offset == 0 causes it to stop buffering
        offset = @offset
        offset = 0.000001 if offset == 0
        @el.jPlayer 'pause', offset

  handles:
    seeked: (event) =>
      if -0.1 < @offset - event.jPlayer.status.currentTime < 0.1
        this.resolve event.jPlayer.status
      else
        if ++@seekAttemptCount < 3
          @el.jPlayer.pause @offset
        else
          this.reject 'Failed to seek after reaching attempt limit'

  # TODO:
  # IOS will some times omit seeking (both the actual seek and the
  # following seeked event are missing) and just start playing from
  # the start of the stream. We detect this here and do another seek
  # if it is the case.
  # This will cause a loop if the play event arrives later than 0.5
  # seconds after playback has started.
