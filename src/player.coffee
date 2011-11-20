# This module handles playback of current media and timing of transcript updates

LYT.player = 
  ready: false 
  el: null
  media: null #id, start, end, text
  section: null
  time: ""
  book: null #reference to an instance of book class
  togglePlayButton: null
  playing: false
  # todo: consider array of all played sections and a few following
  
  setup: ->
    # Initialize jplayer and set ready True when ready
    @el = jQuery("#jplayer")
    @togglePlayButton = jQuery("a.toggle-play")
    
    jplayer = @el.jPlayer
      ready: =>
        @ready = true
              
        @togglePlayButton.click =>
          if @playing
            @el.jPlayer('pause')
          else
            @el.jPlayer('play')
                
        null
      
      timeupdate: (event) =>
        @updateText(event.jPlayer.status.currentTime)
      
      play: (event) =>
        @togglePlayButton.find("img").attr('src', '/images/pause.png')
        @playing = true
      
      pause: (event) =>
        @togglePlayButton.find("img").attr('src', '/images/play.png')
        @playing = false
      
      ended: (event) =>
        @playing = false
      
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
    
    'playing'
  
  updateText: (time) ->
    # Continously update media for current time of section
    @time = time
    if @media.end < @time
      #log.message('current media has ended at ' + @media.end + ' getting new media for ' + @time ) 
      @book.mediaFor(@section.id,@time).done (media) =>
        if media
          @media = media
          @renderText()
        else
          log.message 'failed to get media'
  
  renderText: () ->
    jQuery("#book-text-content").html("<p id='#{@media.id}'>#{@media.text}</p>")
  
  loadBook: (book, section, offset) ->
    @book = book
    # select section or take first off book.sections
    
    @section = section
    
    @book.mediaFor(@section.id,0).done (media) =>
      log.message media
      if media
        @media = media
        @el.jPlayer('setMedia', {mp3: media.audio})
        @renderText()
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
     

  