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
  book: null #reference to an instance of book class
  playlist: null # reference to an instance of LYT.Playlist
  nextButton: null
  previousButton: null
  playIntentOffset: null
  playIntentFlag: false
  
  autoProgression: true 
  toggleAutoProgression: null
  progressionMode: null
  nextButton: null
  previousButton: null
  
  init: ->
    log.message 'Player: starting initialization'
    # Initialize jplayer and set ready True when ready
    @el = jQuery("#jplayer")
    @nextButton = jQuery("a.next-section")
    @previousButton = jQuery("a.previous-section")
    
    @progressionMode = @PROGRESSION_MODES.MP3
    
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
        if @autoProgression
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
    
    return if @media.start < @time <= @media.end
    
    @media = @section.mediaAtOffset @time
    
    if not @media?
      log.warn "Player: failed to get media segment for offset #{@time}"
      return
    
    @renderTranscript()
  
  renderTranscript: () ->
    jQuery("#book-text-content").html @media.html
    # TODO: Possibly add "onload" handlers to images in the HTML
    # and pause the playback until they're all there?
  
  # FIXME: Temporary playlist-using implementation below! Clean it up
  
  loadSection: (book, section, offset = 0, autoPlay = false) ->
    @pause()
    @book = book
    
    @playlist = book.getPlaylist section
    @playlist.done =>
      @playSection @playlist.getCurrentSection(), offset, autoPlay
    
    @playlist.fail ->
      log.error "Player: Failed to get playlist"
      
  playSection: (@section, offset = 0, autoPlay = true) ->
    # TODO: Preload next/previous sections by calling @playlist.getNextSection()/@playlist.getPreviousSection()
    @section.done =>
      @media = @section.mediaAtOffset offset
      unless @media?
        log.message "Player: failed to get media"
        return
      
      @renderTranscript()
      @el.jPlayer "setMedia", {mp3: @media.audio}
      @el.jPlayer "load"
      @play offset, true if autoPlay
    
    @section.fail ->
      log.error "Player: Failed to load section #{section}"
  
  nextSection: ->
    return null unless @playlist?.hasNextSection()
    @playSection @playlist.next(), 0, true
  
  previousSection: ->
    return null unless @playlist?.hasPreviousSection()
    @playSection @playlist.previous(), 0, true
    
