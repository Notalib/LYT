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
duration = 12   # How long time to play the audio before measuring playback rate
minDuration = 3

# Just fail the test on timeout
setTimeout(
  -> Modernizr.addTest 'playbackrate', false unless Modernizr.playbackrate?
  (duration + 1) * 1000
)

try
  source = document.createElement 'source'
  source.setAttribute 'type', 'audio/mpeg'
  source.setAttribute 'src', 'audio/silence.mp3'
  
  audio = document.createElement 'audio'
  audio.appendChild source
  audio.pause()
  audio.playbackRate = rate
  audio.defaultPlaybackRate = rate
  audio.volume = 0
  # Note that play delays before file actually starts playing
  audio.play()
  audio.playbackRate = null
  audio.defaultPlaybackRate = null
  audio.playbackRate = rate
  audio.defaultPlaybackRate = rate
    
  started = new Date() / 1000 - audio.currentTime
  audio.addEventListener 'timeupdate', ->
    # Skip events fired before audio plays or events with invalid time
    # Occurs on Chrome and IOS
    return if audio.paused or isNaN audio.currentTime
    if not started?
      started = new Date() / 1000 - audio.currentTime
      return
    delta = new Date() / 1000 - started
    return if Modernizr.playbackrate? or minDuration > delta    
    if not isNaN(audio.currentTime) and (rate - margin) < audio.currentTime / delta < (rate + margin)
      Modernizr.addTest 'playbackrate', true
      audio.pause()
catch e
  # NOP
