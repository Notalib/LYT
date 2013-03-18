# Requires `/controllers/player/command`
# -------------------

class LYT.player.command.play extends LYT.player.command

  constructor: (el) ->
    super el
    @_run => @el.jPlayer 'play'

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

