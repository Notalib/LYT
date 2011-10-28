
class Player
    startTime: 0
    stopTime: 0
    beginPolling: 0
    lastPartNCCJump: false
    userPaused: false
    playerReady: false
    player: undefined
    
    constructor: () ->
        @player = $("#jplayer").jPlayer
            ready: ->
                @playerReady = true
        
            swfPath: "/js/lib/jPlayer/Jplayer.swf"
            supplied: "mp3"
            
    
    


window.Player = Player


#jPlayer("setMedia", media)
#jPlayer("play")
#jPlayer("pause")
#jPlayer("pauseOthers")
#jPlayer("stop")
#http://jplayer.org/latest/developer-guide/