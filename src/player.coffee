LYT.player =

  init: ->
    $("#jplayer").jPlayer
      ready: ->
        return 'ready'
        
      swfPath: "/lib/jplayer"
      supplied: "mp3"
      
  
  