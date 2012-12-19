# -------------------------------------------
# Modernizr test: audio supports playbackrate
# -------------------------------------------

# Note that this test is asynchronous
# - it won't set result until after a few seconds

# This test doesn't run on IOS because the user has to click a play button
# before playback will start. But on IOS, setting playbackRate isn't supported
# anyway, so this test will return false on that platform because it times out.
 
margin = 0.25  # Margin that the measured playback rate should be within
rate = 0.5     # Test rate
duration = 2   # How long time to play the audio before measuring playback rate

# Just fail the test on timeout
setTimeout(
  -> Modernizr.addTest 'playbackrate', false unless Modernizr.playbackrate?
  (duration + 1) * 1000
)

LYT.playbackrate = do ->

  isPlayBackRateSupported = ->
    deferred = jQuery.Deferred()

    try
      started = null
      audio = document.createElement 'audio'
      audio.addEventListener 'timeupdate', ->
        delta = (new Date() - started) / 1000
        return if delta < duration
        return if audio.paused # Guard against more events
        audio.pause()
        Modernizr.addTest 'playbackrate', not isNaN audio.currentTime and (rate - margin) < audio.currentTime / delta < (rate + margin)
        deferred.resolve()
  
      source = document.createElement 'source'
      source.setAttribute 'type', 'audio/mpeg'
      source.setAttribute 'src', 'audio/silence.mp3'
      audio.appendChild source
      audio.playbackRate = rate
      audio.volume = 0
      audio.play()
    catch e
      deferred.reject()
    # NOP
    deferred.promise()

  isPlayBackRateSupported()


   # ## Public API
  isPlayBackRateSupported:        isPlayBackRateSupported
  