# This module handles playback of current media and timing of transcript updates
# todo: provide a visual cue on the next and previous section buttons if there are no next or previous section.

LYT.player = 
  SILENTMEDIA: "http://m.nota.nu/sound/dixie.mp3" #dixie chicks as we test, replace with silent mp3 when moving to production
  PROGRESSION_MODES:
    MP3:  'mp3'
    TEXT: 'text'
  
  ready: false 
  el: null
  
  media: null
  section: null
  time: ""
  book: null
  
  playIntentOffset: null
  playIntentFlag: false
  
  autoProgression: true 
  toggleAutoProgression: null
  progressionMode: @PROGRESSION_MODES.MP3
  
  nextButton: null
  previousButton: null
  
  init: ->
    log.message 'Player: starting initialization'
    # Initialize jplayer and set ready True when ready
    @el = jQuery("#jplayer")  
    @nextButton = jQuery("a.next-section")
    @previousButton = jQuery("a.previous-section")
    
    jplayer = @el.jPlayer
      ready: =>
        @ready = true
        log.message 'Player: initialization complete'
        #@el.jPlayer('setMedia', {mp3: @SILENTMEDIA})
        #todo: add a silent state where we do not play on can play   
        
        $.jPlayer.timeFormat.showHour = true
        
        @nextButton.click =>
          @nextSection()
        
        @previousButton.click =>
          @previousSection()
                     
      timeupdate: (event) =>
        @updateHtml(event.jPlayer.status)
      
      loadstart: (event) =>
        log.message 'load start'
        @updateHtml(event.jPlayer.status)
      
      ended: (event) =>
        if autoAdvance
          @nextSection()
      
      canplay: (event) =>
        #is not called in firefox 
        log.message 'can play'
        @playOnIntent()
        @updateHtml(event.jPlayer.status)       
      
      progress: (event) =>
        #is not called in chrome
        log.message 'progress'
        @playOnIntent()
        @updateHtml(event.jPlayer.status)        
      
      error: (event) =>
        switch event.jPlayer.error.type
          when $.jPlayer.error.URL
            log.message 'jPlayer: url error'
            # try again before reporting error to user
          when $.jPlayer.error.NO_SOLUTION
            log.message 'jPlayer: no solution error, you need to install flash or update your browser.'

      
      swfPath: "./lib/jPlayer/"
      supplied: "mp3"
      solution: 'html, flash'
    
    
  pause: ->
    # Pause playback
    @el.jPlayer('pause')
  
  getStatus: ->
    # Be cautious only read from status
    @el.data('jPlayer').status
  
  silentPlay: () ->
      ###
      IOS does not allow playing audio without a direct connection to a click event
      we get around this here by starting playback of a silent audio file while 
      the book media loads.
      ###
      
      @el.jPlayer('setMedia', {mp3: @SILENTMEDIA})
      @play(0)
  
  stop: () ->
    # Stop playback and loading of media
    @el.jPlayer('stop')
  
  playOnIntent: () ->
    # Calls play and resets flag if the intent flag was set
    
    if @playIntentFlag
      log.message 'Player: play intent used'
      @play(@playIntentOffset)  
      @playIntentFlag = false
      @playIntentOffset = null
              
  
  play: (time, intent = false) ->
    # Start or resume playing if media is loaded
    # Starts playing at time seconds if specified, else from 
    # when media was paused or from the beginning.
    
    if intent
      log.message 'Player: play intent flag set'
      @playIntentFlag = true
      @playIntentOffset = time
      
    else
      log.message 'Player: Play'
      if not time?
        @el.jPlayer('play')
      else
        @el.jPlayer('play', time)
  
  updateHtml: (status) ->
    # Continously update player rendering for current time of section
    
    return unless @book?
    return unless @media?
    
    @time = status.currentTime
    
    if @media.end < @time
      @book.mediaFor(@section,@time).done (media) =>
        if media?
          #log.message @media
          @media = media
          @renderTranscript()
        else
          log.message 'Player: failed to get media'
  
  renderTranscript: () ->
    #log.message("Player: render new transcript")
    jQuery("#book-text-content").html("<div id='#{@media.id}'>#{@media.html}</div>")
  
  loadSection: (book, section, offset = 0, autoPlay = false) ->
    @pause()
    @book = book
    @section = section
    
    @book.mediaFor(@section, offset).done (media) =>
      #log.message media
      if media?
        @media = media
        @renderTranscript()
        @el.jPlayer('setMedia', {mp3: media.audio})
        @el.jPlayer('load')
        if autoPlay
          @play(offset, true)
      else
        log.message 'Player: failed to get media'
          
  nextSection: () ->   
    #todo: emit some event to let the app know that we should change the url to reflect the new section being played and render new section title
    return unless @media.nextSection?
    @loadSection(@book, @media.nextSection, 0, true)
    
  previousSection: () ->  
    return unless @media.previousSection?
    @loadSection(@book, @media.previousSection, 0, true)
