# This module handles playback of current media and timing of transcript updates

LYT.player = 
  ready: false 
  el: null
  media: null #id, start, end, html
  section: null
  time: ""
  book: null #reference to an instance of book class
  togglePlayButton: null
  nextButton: null
  previousButton: null
  playing: false
  # todo: consider array of all played sections and a few following
  
  SILENTMEDIA: "http://m.nota.nu/sound/dixie.mp3" #dixie chicks as we test, replace with silent mp3 when moving to production
  
  setup: ->
    log.message 'Player: starting setup'
    # Initialize jplayer and set ready True when ready
    @el = jQuery("#jplayer")
    
    @togglePlayButton = jQuery("a.toggle-play")
    @nextButton = jQuery("a.next-section")
    @previousButton = jQuery("a.previous-section")
    
    jplayer = @el.jPlayer
      ready: =>
        @ready = true
        log.message 'Player: setup complete'
        #@el.jPlayer('setMedia', {mp3: @SILENTMEDIA})
        #todo: add a silent state where we do not play on can play   
        
        @nextButton.click =>
          @nextSection()
        
        @previousButton.click =>
          @previousSection()
        
        @togglePlayButton.click =>
          if @playing
            @el.jPlayer('pause')
          else
            @el.jPlayer('play')
                
        null
      
      timeupdate: (event) =>
        @updateHtml(event.jPlayer.status.currentTime)
      
      play: (event) =>
        @togglePlayButton.find("img").attr('src', '/images/pause.png')
        @playing = true
      
      pause: (event) =>
        @togglePlayButton.find("img").attr('src', '/images/play.png')
        @playing = false
      
      ended: (event) =>
        @nextSection()
      
      canplay: (event) =>
        log.message 'can play'
        @play()
      
      progress: (event) =>
        log.message 'progress'
        @renderHtml()
      
      swfPath: "./lib/jPlayer/"
      supplied: "mp3"
      solution: 'html, flash'
    
    @ready
    
  pause: ->
    # Pause current media
    @el.jPlayer('pause')
    
    'paused'
  
  silentPlay: () ->
      ###
      IOS does not allow playing audio without a direct connection to a click event
      we get around this here by starting playback of a silent audio file while 
      the book media loads.
      ###
      
      @el.jPlayer('setMedia', {mp3: @SILENTMEDIA})
      @play(0)
  
  stop: ->
    @el.jPlayer('stop')
    
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
  
  updateHtml: (time) ->
    # Continously update media for current time of section
    return unless @book?
    return unless @media?
    @time = time
    if @media.end < @time
      log.message("Player: current media has ended at #{@media.end} getting new media for #{@time}") 
      @book.mediaFor(@section,@time).done (media) =>
        if media
          @media = media
          @renderHtml()
        else
          log.message 'Player: failed to get media'
  
  renderHtml: () ->
    jQuery("#book-text-content").html("<div id='#{@media.id}'>#{@media.html}</div>")
  
  loadSection: (book, section, offset = 0) ->
    #alert "Player: load book"
    @book = book
    @section = section
    
    @book.mediaFor(@section, offset).done (media) =>
      log.message media
      if media
        @media = media
        @el.jPlayer('setMedia', {mp3: media.audio})
      else
        log.message 'Player: failed to get media'
          
  nextSection: () ->
    
    #todo: emit some event to let the app know that we should change the url to reflect the new section being played and render new section title
    return unless @media.nextSection?
    @pause()
    @loadSection(@book, @media.nextSection)
    
  previousSection: () ->
    
    return unless @media.previousSection?
    @pause()
    @loadSection(@book, @media.previousSection)
     

  