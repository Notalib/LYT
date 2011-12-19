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
        
        # TODO: Disable next/prev buttons if there are not next/prev sections?
        # FIXME: Needs more error checking
        @nextButton.click =>
          if @media?.hasNext()
            @media = @media.getNext()
            @play @media.start
          else
            @nextSection()
        
        @previousButton.click =>
          if @media?.hasPrevious()
            @media = @media.getPrevious()
            @play @media.start
          else
            @previousSection()
                     
      timeupdate: (event) =>
        @updateHtml(event.jPlayer.status)
      
      loadstart: (event) =>
        log.message 'Player: load start'
        @updateHtml(event.jPlayer.status)
        if jQuery.browser.webkit
          @playOnIntent()
      
      ended: (event) =>
        if @autoProgression
          @nextSection()
      
      canplaythrough: (event) =>
        log.message 'Player: event can play through'
        @playOnIntent()
      
      loadeddata: (event) =>
        log.message 'Player: event loaded data'
        @playOnIntent()
      
      canplay: (event) =>
        log.message 'Player: event can play'
        @playOnIntent()
      
      progress: (event) =>
        log.message 'Player: event progress'
        @playOnIntent()
      
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
      @play(@playIntentOffset, false)  
      @playIntentFlag = false
      @playIntentOffset = null
              
  
  play: (time, setIntent = true) ->
    # Start or resume playing if media is loaded
    # Starts playing at time seconds if specified, else from 
    # when media was paused or from the beginning.
    
    # android, chrome, ipad and firefox uses and intent
    # safari uses a immediate play
    
    if setIntent
      log.message 'Player: play intent flag set'
      @playIntentFlag = true
      @playIntentOffset = time
      
      if $.jPlayer.platform.iphone
        @playOnIntent()
      
    else
      log.message 'Player: Play'
      if not time?
        @el.jPlayer('play')
      else
        @el.jPlayer('play', time)
        
      
  
  updateHtml: (status) ->
    # Continously update player rendering for current time of section
    return unless @book?
    
    @time = status.currentTime
    
    return if @media? and @media.start < @time <= @media.end
    
    @media = @section.mediaAtOffset @time
    
    log.warn "Player: failed to get media segment for offset #{@time}" unless @media?
    
    @renderTranscript()
  
  
  renderTranscript: () ->
    if @media?
      jQuery("#book-text-content").html @media.html
      # TODO: Possibly add "onload" handlers to images in the HTML
      # and pause the playback until they're all there?
      return
    
    # If there's no media, show nothing
    jQuery("#book-text-content").empty()
  
  
  whenReady: (callback) ->
    if @ready
      callback()
    else
      @el.bind $.jPlayer.event.ready, callback
  
  load: (book, section = null, offset = 0, autoPlay = false) ->
    return if book.id is @book?.id
    @book = book
    
    log.message "Player: Loading book #{book.id}, setion #{section}, offset: #{offset}"
    @book.done =>
      jQuery("#book-duration").text @book.totalTime
      @whenReady =>
        @playlist = book.getPlaylist section
        
        @playlist.done =>
          @playSection @playlist.getCurrentSection(), offset, autoPlay
        
        @playlist.fail =>
          log.error "Player: Failed to get playlist"
  
  
  playSection: (section, offset = 0, autoPlay = true) ->
    return if section is @section
    @section = section
    
    @section.done =>
      log.message "Player: Playlist current section #{@section.id}"
      
      # Preload the next/prev sections
      @playlist.getNextSection() if @playlist.hasNextSection()
      @playlist.getPreviousSection() if @playlist.hasPreviousSection()
      
      # Get the media obj
      @media = @section.mediaAtOffset offset
      @renderTranscript()
      
      if @media?
        @el.jPlayer "setMedia", {mp3: @media.audio}
      else
        # If no media was found, check whether the section has a single,
        # unambiguous MP3 file, we can load instead
        log.warn "Player: failed to get media"
        mp3s = @section.getAudioUrls()
        if mp3s.length isnt 1
          # No media, no MP3: Just give up...
          log.error "Player: Couldn't determine MP3 file"
          return
        @el.jPlayer "setMedia", {mp3: mp3s.pop()}
      
      @el.jPlayer "load"
      @play offset if autoPlay
    
    @section.fail ->
      log.error "Player: Failed to load section #{section}"
  
  
  nextSection: ->
    return null unless @playlist?.hasNextSection()
    @playSection @playlist.next(), 0, true
  
  
  previousSection: ->
    return null unless @playlist?.hasPreviousSection()
    @playSection @playlist.previous(), 0, true
    
