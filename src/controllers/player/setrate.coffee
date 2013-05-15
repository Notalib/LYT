# Requires `/controllers/player/command`
# --------------------------------------

# ########################################################################### #
# Set playback rate                                                           #
# ########################################################################### # 

class LYT.player.command.setRate extends LYT.player.command

  constructor: (el, @playbackRate) ->
    super el
    if not @playbackRate or @playbackRate < 0.5
      this.reject "The playback rate #{@playbackRate} is out of range"
    else
      @src = @status().src
      @_run()

  handles: ->
    timeupdate: (event) =>
      status = @status()
      if status.src
        if status.src is @src
          if not isNaN status.currentTime
            if audio = @el.children('audio')[0]
              audio.playbackRate = @playbackRate
              @resolve()
        else
          @reject()
      # else just ignore the event


