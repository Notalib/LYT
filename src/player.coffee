# This module handles playback of current media and timing of transcript updates

LYT.player =
  
  ready: false 
  el: null
  media: null #id, start, end, text
  section: null
  time: ""
  book: null #reference to an instance of book class
  
  # todo: consider array of all played sections and a few following
  
  
  setup: ->
    # Initialize jplayer and set ready True when ready
    @el = jQuery("#jplayer")
    jplayer = @el.jPlayer
      ready: =>
        @ready = true
        
        @el.bind jQuery.jPlayer.event.timeupdate, (event) =>
          @update(event.jPlayer.status.currentTime)
        
        @el.bind jQuery.jPlayer.event.ended, (event) =>
          @update(event.jPlayer.status.currentTime)
        
        null
      
      swfPath: "./lib/jPlayer/"
      supplied: "mp3"
      solution: 'html, flash'
    
    @ready
    
  pause: ->
    # Pause current media
    @el.jPlayer('pause')
    
    null
  
  stop: ->
    # Stop playing and stop downloading current media file
    @el.jPlayer('stop')
    @el.jPlayer('clearMedia')
    
    'stopped'
  
  play: (time) ->
    # Start or resume playing if media is loaded
    # Starts playing at time seconds if specified, else from 
    # when media was paused, else from the beginning.
    if not time?
      @el.jPlayer('play')
    else
      @el.jPlayer('play', time)
    
    log.message('now playing')
    
    'playing'
  
  updateText: (time) ->
    #log.message('update text')
    # Continously update media for current time of section
    @time = time
          
    if @currentTranscript.end < @time
      #LYT.gui.hideTranscript("")
      log.message('hide transcript')
      
    else if @currentTranscript.start >= @time
      #LYT.gui.updateTranscript("")
      #LYT.gui.showTranscript("")
      log.message('show transcript')
     
  loadBook: (book, section, offset) ->
    @book = book
    # select section or take first off book.sections
    
    @book.mediaFor(null,0).done (media) =>
      log.message media
      if media
        @media = media
        @el.jPlayer('setMedia', {mp3: media.audio})
        @play()
      else
        log.message 'could not get media'
    
      
  nextPart: () ->
    @stop()
    # get next part
    @load()
    
  previousPart: () ->
    @stop()
    # get next part
    @load()
     

  