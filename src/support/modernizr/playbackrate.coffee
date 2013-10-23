# -------------------------------------------
# Modernizr test: audio supports playbackrate
# -------------------------------------------

# Note that this test is asynchronous
# - it won't set result until after a few seconds

runTest = ->
  margin = 0.1    # Margin that the measured playback rate should be within
  rate = 0.5      # Test rate
  duration = 12   # How long time to play the audio before measuring playback rate
  minDuration = 3 # Shortest duration in seconds before testing

  # Structure setup
  source = document.createElement 'source'
  source.setAttribute 'type', 'audio/mpeg'
  source.setAttribute 'src', 'audio/silence.mp3'
  audio = document.createElement 'audio'
  audio.appendChild source

  # Test block
  # Handler that checks if the playbackRate is correct and tells Modernizr
  started = null
  rateSet = false
  audio.addEventListener 'timeupdate', ->
    console.log 'timeupdate'
    # Don't do anything if the test has finished
    return if Modernizr.playbackrate?

    if not rateSet and not isNaN audio.currentTime
      audio.playbackRate = rate
      rateSet = true
    # Skip events fired before audio plays or events with invalid time.
    # Occurs on Chrome and IOS.
    return if audio.paused or isNaN audio.currentTime or audio.currentTime == 0

    # Record the time at which the audio started playing
    if not started?
      return started = Date.now() / 1000 - audio.currentTime

    # Get time in seconds since audio started playing and return if played
    # for too short time
    delta = Date.now() / 1000 - started
    return if minDuration > delta

    # Calculate the actual playback rate and set test result
    playbackRate = audio.currentTime / delta
    if (rate - margin) < playbackRate < (rate + margin)
      Modernizr.addTest 'playbackrate', true
      audio.pause()

  # Just fail the test on timeout
  setTimeout( ->
    -> Modernizr.addTest 'playbackrate', Modernizr.playbackrate?
    (duration + 1) * 1000
  )

  # Start playback
  audio.play()

Modernizr.on 'autoplayback', (autoplayback) ->
  if not autoplayback
    # IOS prohibits web pages from starting any audio playback automatically, so
    # we fall back to wait for user interaction before running the test.
    listener = ->
      document.removeEventListener 'click', listener
      runTest()
    document.addEventListener 'click', listener
  else
    runTest()

