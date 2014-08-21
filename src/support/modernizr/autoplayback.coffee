# -----------------------------------------------------------------
# Modernizr test: audio playback can start without user interaction
# -----------------------------------------------------------------

# Note that this test is asynchronous
# - it won't set result until after a few seconds
try
  log.message "Tests: autoplayback test is running"

  source = document.createElement 'source'
  source.setAttribute 'type', 'audio/mpeg'
  source.setAttribute 'src', 'audio/silence.mp3'

  # Note the absent document.body.appenChild audio
  # It works without it and this test would be very complicated it would be
  # necessary because it requires hooking into the equivalent of
  # $(document).ready event (without jQuery).
  audio = document.createElement 'audio'
  audio.appendChild source

  timeHandler = ->
    if not Modernizr.autoplayback? and not isNaN(audio.currentTime) and audio.currentTime > 0
      log.message "Tests: autoplayback: is playing"
      Modernizr.addTest 'autoplayback', true
      audio.pause()
      audio.removeEventListener 'timeupdate', timeHandler
      clearTimeout failTimeout

  # Just fail the test on timeout
  failTimeout = setTimeout( ->
    Modernizr.addTest 'autoplayback', false unless Modernizr.autoplayback?

    log.message "Tests: autoplayback: failTimeout: #{Modernizr.autoplayback}"
    audio.removeEventListener 'timeupdate', timeHandler
  , 2000
  )

  audio.play()
  audio.addEventListener 'timeupdate', timeHandler
catch e
  # NOP
