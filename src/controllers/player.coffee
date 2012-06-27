# Requires `/common`  
# Requires `/support/lyt/loader`  

# -------------------

# This module handles playback of current media and timing of transcript updates  
# TODO: provide a visual cue on the next and previous section buttons if there are no next or previous section.

LYT.player = 
  SILENTMEDIA: "http://m.nota.nu/sound/dixie.mp3" # FIXME: dixie chicks as we test, replace with silent mp3 when moving to production
  PROGRESSION_MODES:
    MP3:  'mp3'
    TEXT: 'text'
  
  ready: false 
  el: null
  
  time: ""
  book: null #reference to an instance of book class
  playlist: -> @book?.playlist
  nextButton: null
  previousButton: null
  playIntentOffset: 0
  playIntentFlag: false

  autoProgression: true 
  toggleAutoProgression: null
  progressionMode: null
  
  fakeEndScheduled: false
  
  # Number of segments to preload
  segmentLookahead: 3
  
  _iBug: false
  
  playAttemptCount: 0
  gotDuration : null
  playBackRate : 1 #Default playBackRate for audio element....
  
  
  lastBookmark: (new Date).getTime()
  
  segment: -> @playlist().currentSegment
  
  section: -> @playlist().currentSection()
  
  init: ->
    log.message 'Player: starting initialization'
    # Initialize jplayer and set ready True when ready
    @el = jQuery("#jplayer")
    @nextButton = jQuery("a.next-section")
    @previousButton = jQuery("a.previous-section")
    @progressionMode = @PROGRESSION_MODES.MP3
    @currentAudio = ''
         
    jplayer = @el.jPlayer
      ready: =>
        @ready = true
        log.message 'Player: initialization complete'
        #@el.jPlayer('setMedia', {mp3: @SILENTMEDIA})
        #todo: add a silent state where we do not play on can play   
        
        $.jPlayer.timeFormat.showHour = true
        
        @nextButton.click =>
          log.message 'Player: next'
          @nextSegment()
            
        @previousButton.click =>
          log.message 'Player: prev'
          @previousSegment()
      
      timeupdate: (event) =>
        #@fakeEnd(event.jPlayer.status) 
        @updateHtml(event.jPlayer.status)
      
      loadstart: (event) =>
        log.message 'Player: load start'
        @setPlayBackRate()
        if(@playAttemptCount < 1 and ($.jPlayer.platform.iphone or $.jPlayer.platform.ipad or $.jPlayer.platform.iPod))
          if (!LYT.config.player.IOSFirstPlay and $.mobile.activePage[0].id is 'book-play')
            # IOS will not AutoPlay...
            LYT.loader.set('Loading sound', 'metadata') 

        else if(@playAttemptCount < 1 and $.mobile.activePage[0].id is 'book-play')
          #Only make the loading sign the first time...
          LYT.loader.set('Loading sound', 'metadata') 
        
        return if $.jPlayer.platform.android

        return if ($.jPlayer.platform.iphone or $.jPlayer.platform.ipad or $.jPlayer.platform.iPod)
        
        return unless jQuery.browser.webkit
        
        @updateHtml(event.jPlayer.status)
        @playOnIntent()
      
      ended: (event) =>
        if @autoProgression
          @nextSegment true  
      
      pause: (event) =>
        status = event.jPlayer.status
        return unless @isIOS()
        if @_iBug
          log.warn 'we are ibug'
          #@el.jPlayer('load')
          
        else if status.duration > 0 and jQuery.jPlayer.convertTime(status.duration) is not 'NaN' and jQuery.jPlayer.convertTime(status.duration) is not '00:00' and (status.currentTime is 0 or status.currentTime is status.duration)  
          log.warn 'set ibug'
          @_iBug = true
          if @autoProgression
            @nextSegment true
                   
      seeked: (event) =>
        log.message 'Player: event seeked'
        LYT.loader.close('metadata')
        @playOnIntent()

      loadedmetadata: (event) =>
        log.message 'Player: loaded metadata'
        if isNaN( event.jPlayer.status.duration )
          #alert event.jPlayer.status.duration
          @gotDuration = false
          if(@getStatus().src == @currentAudio && @playAttemptCount <= LYT.config.player.playAttemptLimit )
            @el.jPlayer "setMedia", {mp3: @segment().audio}
            @el.jPlayer "load"
            @playAttemptCount = @playAttemptCount + 1 
            log.message "Player: loadedmetadata, play attempts: #{@playAttemptCount}"
          else if ( @playAttemptCount > LYT.config.player.playAttemptLimit)
            @gotDuration = true
            #faking that we got the duration - we don´t but need to play the file now...
            
        else
         @gotDuration = true
         @playAttemptCount = 0
         #LYT.loader.close('metadata')
         
      
      canplay: (event) =>
        log.message 'Player: event can play'
        if @gotDuration
          @gotDuration = false
          #@el.data('jPlayer').htmlElement.audio.currentTime = @playIntentOffset
          #@pause(@playIntentOffset)
          if @playIntentOffset? and @playIntentOffset > 0 and @isIOS()
            
            if LYT.config.player.IOSFirstPlay
              @pause()
          else
            @playOnIntent()
            LYT.loader.close('metadata')
        if(!@gotDuration?)
          LYT.loader.close('metadata') #windows phone 7

      
      canplaythrough: (event) =>
        log.message 'Player: event can play through'
        if @playIntentOffset? and @playIntentOffset > 0 and @isIOS()
          if LYT.config.player.IOSFirstPlay
            LYT.config.player.IOSFirstPlay = false;
            @el.data('jPlayer').htmlElement.audio.currentTime = @playIntentOffset
            @el.data('jPlayer').htmlElement.audio.play()
          else
            @pause(@playIntentOffset)

            @playOnIntent()
            LYT.loader.close('metadata')  
         
        else if LYT.config.player.IOSFirstPlay and @isIOS()
          LYT.config.player.IOSFirstPlay = false;

        
        #@el.data('jPlayer').htmlElement.audio.currentTime = parseFloat("6.4");
        #LYT.loader.close('metadata')
        #@playOnIntent()
      
      progress: (event) =>
        #log.message 'Player: event progress'
        #LYT.loader.close('metadata')
        #@playOnIntent()
      
      error: (event) =>
        switch event.jPlayer.error.type
          when $.jPlayer.error.URL
            log.message 'jPlayer: url error'
            $("#submenu").simpledialog({
                'mode' : 'bool',
                'prompt' : 'Der er opstået en fejl!',
                'subTitle' : 'kunne ikke hente lydfilen.'
                'animate': false,
                'useDialogForceFalse': true,
                'allowReopen': true,
                'useModal': true,
                'buttons' : {
                  'Prøv igen': 
                    click: (event) ->
                      window.location.reload()
                    ,
                    theme: "c"
                  ,
                  'Annuller': 
                    click: (event) ->
                      $.mobile.changePage "#bookshelf"
                    ,
                    theme: "c"
                  ,
                   
                }
              
            })
            #reopen the dialog...
            #TODO: this is usually because something is wrong with the session or the internet connection, 
            # tell people to try and login again, check their internet connection or try again later
          when $.jPlayer.error.NO_SOLUTION
            log.message 'jPlayer: no solution error, you need to install flash or update your browser.'
            #TODO: send people to a link where they can download flash or update their browser
      
      
      swfPath: "./lib/jPlayer/"
      supplied: "mp3"
      solution: 'html, flash'
    
  fakeEnd: (status) ->
    return unless status.duration > 0 and status.currentTime > 1
    timeleft = status.duration - status.currentTime
    if timeleft < 1 and timeleft > 0
      #log.message @fakeEndScheduled
      if @fakeEndScheduled is false
        @fakeEndScheduled = true
        log.warn "Player: segment is #{timeleft} seconds from ending but we can't handle endings - schedule a fake end just before"      
        
        setTimeout (
          => 
            @nextSegment true
            @fakeEndScheduled = false ),
          (timeleft*1000)-50 
    
  pause: (time) ->
    # Pause playback
    log.message "pause at " + time

    if time?
      @playIntentOffset = time
      @el.jPlayer('pause', time)
    else
      #@playIntentOffset = null
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
  
  # TODO: Remove our own playBackRate attribute and use the one on the jPlayer
  #       If it isn't available, there is no reason to try using it.
  setPlayBackRate: (playBackRate) ->
    if playBackRate?
      @playBackRate = playBackRate
    if @el.data('jPlayer').htmlElement.audio?
      if @el.data('jPlayer').htmlElement.audio.playbackRate?
        @el.data('jPlayer').htmlElement.audio.playbackRate = @playBackRate
        log.message "Player: setPlayBackRate: #{@playBackRate}"
        return
    log.message "Player: setPlayBackRate: unable to set playback rate"
  
  # TODO: Don't set the playback rate here
  isPlayBackRateSurpported: ->
    if @el.data('jPlayer').htmlElement.audio.playbackRate?
      return false if $.jPlayer.platform[platform] for platform in ['iphone', 'ipad', 'iPod', 'android']
      return false if /Windows Phone/i.test(navigator.userAgent)
      return true
    else
      return false
  
  stop: () ->
    if @ready?
      @el.jPlayer('stop')
    
  clear: () ->
    if @ready?
      @el.jPlayer('clearMedia')
      
    
  isIOS: () ->
    if /iPad/i.test(navigator.userAgent) or /iPhone/i.test(navigator.userAgent) or /iPod/i.test(navigator.userAgent)
      return true
    else
      return false
  
  playOnIntent: () ->
    # Calls play and resets flag if the intent flag was set
    
    if @playIntentFlag
      #@playAttemptCount = 0
      log.message 'Player: play intent used offset is #{@playIntentOffset}'
      @playIntentFlag = false
      @play(@playIntentOffset, false)
      @playIntentOffset = null
  
  play: (time, setIntent = true) ->
    # Start or resume playing if media is loaded
    # Starts playing at time seconds if specified, else from
    #if time is not ""
      #@pause(time)
    
    if setIntent
      log.message 'Player: play intent flag set'
      @playIntentFlag = true
      @playIntentOffset = time
      
    else
      log.message 'Player: Play'
      @el.jPlayer('play')
        
      
  updateHtml: (status) ->
    # Continously update player rendering for current time of section
    return unless @book?
    
    @time = status.currentTime
    @updateLastMark()
    return if @segment()? and @segment().start <= @time < @segment().end

    segment = @playlist().segmentByOffset @time
    if segment and not @getStatus()?.paused
      segment.done (segment) => segment.preloadNext()
      @updateLastMark()
    
    log.warn "Player: failed to get media segment for offset #{@time}" unless segment?
    
    @renderTranscript(@segment())
  
  
  renderTranscript: (segment) ->
    if segment?
      segment.done (segment) -> LYT.render.textContent(segment)
    else
      # If there's no media, show nothing
      jQuery("#book-text-content").empty()
  
  
  whenReady: (callback) ->
    if @ready
      callback()
    else
      @el.bind $.jPlayer.event.ready, callback
  
  # url: url pointing to section or segment
  load: (book, url = null, offset = 0, autoPlay = true) ->
    #return if book.id is @book?.id
    deferred = jQuery.Deferred()
    load = LYT.Book.load book
    
    #LYT.loader.register "Loading book", @book
    
    log.message "Player: Loading book #{book}, segment #{url}, offset: #{offset}, autoPlay #{autoPlay}"
    load.done (book) =>
      @book = book
      jQuery("#book-duration").text @book.totalTime
      @whenReady =>
        if not url? and book.lastmark?
          url    = book.lastmark.URI
          offset = book.lastmark.offset
          log.message "Player: resuming from lastmark #{url}, offset #{offset}"

        failHandler = () =>
          deferred.reject()
          log.error "Player: failed to find segment"

        doneHandler = (segment) =>
          deferred.resolve @book
          segment.load()
          @playSegment segment, autoPlay
          log.message "Player: found segment #{segment.url()} - playing"

        if url?
          promise = @playlist().segmentByURL url
          promise.done doneHandler
          promise.fail =>
            log.error "Player: failed to load url #{url} - rewinding to start"
            promise = @playlist().rewind()
            promise.done doneHandler
            promise.fail failHandler
        else
          promise = @playlist().rewind()
          promise.done doneHandler
          promise.fail failHandler
        
    deferred.promise()
  
  # TODO: More elegant use of segmentLookahead config value

  playSegment: (segment, autoPlay = true) ->
    throw 'Player: playSegment called with no segment' unless segment?
    segment.done (segment) =>
      @renderTranscript(segment)
      segment.preloadNext()
      if @currentAudio != segment.audio
        @el.jPlayer "setMedia", {mp3: segment.audio}
        @el.jPlayer "load"
        @currentAudio = segment.audio
        
      if @getStatus()?.paused and not autoPlay
        @el.jPlayer "pause", Math.ceil(segment.start)
      else
        @el.jPlayer "play", Math.ceil(segment.start)

  playSection: (section, offset = 0, autoPlay = true) ->
    
    section = @playlist().rewind() unless section?
    
    LYT.loader.register "Loading book", section
    
    section.done =>
      log.message "Player: Playlist current section #{@section().id}"
      jQuery("#player-chapter-title h2").text section.title

      # Get the media obj
      @playlist().segmentByOffset offset
      
      @renderTranscript @segment()

      @playSegment @segment(), autoPlay
      
    section.fail ->
      log.error "Player: Failed to load section #{section}"

  nextSegment: (autoPlay = false) ->
    # FIXME: We shouldn't accept a call to nextSegment if the playlist isn't there
    return null unless @playlist()?
    if @playlist().hasNextSegment() is false
      LYT.render.bookEnd()
      return null
    @playSegment @playlist().nextSegment(), autoPlay

  previousSegment: (autoPlay = false) ->
    return null unless @playlist()?.hasPreviousSegment()
    @playSegment @playlist().previousSegment(), autoPlay
  
  updateLastMark: (force = false) ->
    return unless LYT.session.getCredentials() and LYT.session.getCredentials().username isnt LYT.config.service.guestLogin
    return unless @book? and @section()?
    @segment().done (segment) =>
      now = (new Date).getTime()
      interval = LYT.config.player?.lastmarkUpdateInterval or 10000
      return unless force or not @lastBookmark or now - @lastBookmark > interval
      if @getStatus().currentTime is 0 or @playIntentOffset > @getStatus().currentTime
        return
      @book.setLastmark segment, @getStatus().currentTime
      @lastBookmark = now
  
  getCurrentlyPlaying: ->
    return null unless @book? and @section()?.state() is "resolved"
    book:    @book.id
    section: @section()?.url
    segment: @segment()?.id
    
  getCurrentlyPlayingUrl: (absolute=true, resolution='book') ->
    # Returns the url of the currently playing book
    # Accepts a resolution a string that is either 'book', 'section' or 'offset'
    # Defaults to 'book'
    # If absolute is true it returns the full url with domain
    
    return null unless @book? and @section()?.state() is "resolved"
    
    # FIXME: Don't return urls that only the controllers should know about
    url = "#book-play?book=#{@book.id}"
    if resolution in ['section', 'offset']
      url = url + "&section=#{@section().id}"  
      if resolution is 'offset' and @time?
        url = url + "&offset=#{@time}"
    
    if absolute
      if document.baseURI?
        return document.baseURI + url
      else
        return window.location.hostname+'/'+ url 
    
    return url
