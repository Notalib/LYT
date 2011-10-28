PlayOrPause = ->
  try
    if Player.player.paused
      Player.isUserEvent = true
      Player.userPaused = false
      if rememberSoundFile.length > 0
        GetSound rememberSoundFile[0], rememberSoundFile[1], rememberSoundFile[2]
        rememberSoundFile.length = 0
      else
        Player.player.play()
    else
      Player.isUserEvent = true
      Player.userPaused = true
      Player.player.pause()
  catch e
    alert e.message
    
FF = ->
  unless Player.player.playbackRate is `undefined`
    if Player.player.playbackRate is Player.player.defaultPlaybackRate
      try
        Player.player.playbackRate = 2
      catch err
        alert "kunne ikke spole frem i dette medie"
    else
      try
        Player.player.playbackRate = Player.player.defaultPlaybackRate
      catch err
        alert "kunne ikke indstile playbackrate frem i dette medie"
FR = ->
  unless Player.player.currentTime is `undefined`
    try
      Player.player.currentTime += -5
    catch err
      alert "kunne ikke spole tilbage i dette medie"
      
NextPart = ->
  try
    clearInterval Player.BeginPolling
    Pause()
    audioTagList.shift()  if audioTagList.length > 0
    if textTagList.length > 0
      aTextTag = textTagList.shift()
      GetAllTheText = false
      GetTextAndSoundPiece aTextTag.getAttribute("id"), smilCacheTable[currentSmilFile]
    else GetTextAndSound nextAElement  if nextAElement?
  catch e
    alert e.message
    
LastPart = ->
  try
    clearInterval Player.BeginPolling
    Pause()
    if textTagList.length is tempTextList.length - 1
      if currentAElement.getAttribute("xhref") is PLAYLIST[0].getAttribute("xhref")
        alert "call GUI to show message - reached start of book"
      else
        Player.LastPartNCCJump = true
        LastNCC()
        i = 0

        while i < tempTextList.length
          textTagList.shift()
          i++
        GetTextAndSoundPiece tempTextList[tempTextList.length - 1].getAttribute("id"), smilCacheTable[currentSmilFile]
    else
      if textTagList.length is 0
        textTagList.unshift tempTextList[tempTextList.length - 1]
        GetTextAndSoundPiece tempTextList[tempTextList.length - 2].getAttribute("id"), smilCacheTable[currentSmilFile]
      else
        i = 0

        while i < tempTextList.length
          if textTagList[0] is tempTextList[i]
            if i > 1
              textTagList.unshift tempTextList[i - 1]
              GetTextAndSoundPiece tempTextList[i - 2].getAttribute("id"), smilCacheTable[currentSmilFile]
          i++
  catch e
    alert e.message
    
NextNCC = ->
  try
    GetTextAndSound nextAElement
  catch e
    alert e.message
    
LastNCC = ->
  try
    temp = GetLastAElement(currentAElement)
    GetTextAndSound temp  if temp?
  catch e
    alert e.message