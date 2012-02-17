    
###
if @getStatus().duration is null
  #alert(@getStatus().src)
  
  if @playAttemptCount <= 9
    @playAttemptCount += 1
    
    # try to trigger seeked event setting currenTime manually    
    #log.warn "Player: duration (#{@getStatus().duration}) is none trying to force seeked event in 500ms"  
    
    #jQuery('#jplayer').data('jPlayer').status.duration = 3000
    setTimeout(jQuery('#jplayer').data('jPlayer').status.duration = 3000, 500)
    setTimeout(jQuery('#jplayer').data('jPlayer').status.currentTime = 0.5, 500)
    log.warn "Duration is #{@getStatus().duration}"
    
    #triggerSeekedHack = () =>
    #  status = @getStatus()
    #  status.currentTime = 0.5
    #  #status.duration = 2000
    #  jQuery.data(@el, 'jPlayer', status)
    
    #@el.jPlayer("playHead", 1)
    
    log.warn "Player: duration (#{@getStatus().duration}) is none retrying play in 600ms | Tried #{@playAttemptCount} of 10 times"
    setTimeout(@playOnIntent(), 600)
    
else
###