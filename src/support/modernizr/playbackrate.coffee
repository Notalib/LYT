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
  audio.addEventListener 'timeupdate', ->
    # Don't do anything if the test has finished
    return if Modernizr.playbackRate?

    # Skip events fired before audio plays or events with invalid time.
    # Occurs on Chrome and IOS.
    return if audio.paused or isNaN audio.currentTime or audio.currentTime == 0
    if not started?
      started = new Date() / 1000 - audio.currentTime
      return

    # Get time in seconds since audio started playing and return if played
    # for too short time
    delta = new Date() / 1000 - started
    return if minDuration > delta

    # Calculate the actual playback rate and run test
    if not isNaN(audio.currentTime) and (rate - margin) < audio.currentTime / delta < (rate + margin)
      Modernizr.addTest 'playbackRate', true

  # Just fail the test on timeout
  timeoutHandler = ->
    return if Modernizr.playbackRate?
    Modernizr.addTest 'playbackRate', false
  setTimeout timeoutHandler, (duration + 1) * 1000

  # Set block
  # Handler that sets the playbackRate when the audio object is ready
  rateSet = false
  audio.addEventListener 'timeupdate', ->
    if not isNaN(audio.currentTime) and not rateSet
      audio.playbackRate = rate
      rateSet = true

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

