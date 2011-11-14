# This module handles playback of current media and timing of transcript updates

LYT.player =
  
  ready: false 
  jplayer: null
  el: jQuery("#jplayer")
  currentTranscript: null #id, start, end, text
  currentMedia: ""
  currentTime: ""
  
  setup: =>
    # Initialize jplayer and set ready True when ready
    @jplayer = @el.jPlayer
      ready: =>      
        @el.bind jQuery.jPlayer.event.timeupdate, (event) =>
          # Continously update transcript for current time of media
          @currentTime = event.jPlayer.status.currentTime
          
          if not currentTranscript? or currentTranscript.end < @currentTime
            # update transcript if we don't have one or if it is in the past
            @currentTranscript = LYT.Book.getTranscriptForTime @currentMedia, @currentTime
            
          if @currentTranscript.end < @currentTime
            # hide transcript
            
          else if @currentTranscript.start >= @currentTime
            # update and show transcript
          
        @ready = True
      
      swfPath: "/lib/jplayer"
      supplied: "mp3"
      solution: 'html, flash'
      
  pause: =>
    # Pause current media
    @jplayer('pause')
  
  stop: =>
    # Stop playing and stop downloading current media file
    @jplayer('stop')
    @jplayer('clearmedia')
  
  load: (media) =>
    if @currentMedia is not media
      @jplayer('setmedia', media)
      @currentMedia = media
  
  play: (time) =>
    # Start or resume playing if media is loaded
    # Starts playing at time seconds if specified, else from 
    # when media was paused, else from the beginning.
    if not time?
      @jplayer('play')
    else
      @jplayer('play', time)
    

  