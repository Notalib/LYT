# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.play extends LYT.player.command

  constructor: (el) ->
    super el
    @_run =>
      @el.jPlayer 'play'
      setTimeout(
        => @reject 'timeout' if @state() is 'pending'
        10000
      )
#      retryInterval = setInterval(
#        =>
#          if not @playing
#            log.message 'Playcommand timeout: play'
#            @el.jPlayer 'play'
#          else
#            clearInterval retryInterval
#        2000
#      )

  cancel: ->
    super()
    @el.jPlayer 'pause'

  _stop: (event) ->
    method = if @canceled then @reject else @resolve
    method.apply this, event.jPlayer.status
    
  handles: ->
    playing: (event) =>
      @playing = true
      @notify event.jPlayer.status

    timeupdate: (event) =>
      if @playing and event.jPlayer.status.paused
        @_stop event
      else
        @notify event.jPlayer.status

    ended: (event) => @_stop event

    pause: (event) => @_stop event

