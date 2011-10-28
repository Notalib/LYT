(function() {
  var Player;
  Player = (function() {
    Player.prototype.startTime = 0;
    Player.prototype.stopTime = 0;
    Player.prototype.beginPolling = 0;
    Player.prototype.lastPartNCCJump = false;
    Player.prototype.userPaused = false;
    Player.prototype.playerReady = false;
    Player.prototype.player = void 0;
    function Player() {
      this.player = $("#jplayer").jPlayer({
        ready: function() {
          return this.playerReady = true;
        },
        swfPath: "/js/lib/jPlayer/Jplayer.swf",
        supplied: "mp3"
      });
    }
    return Player;
  })();
  window.Player = Player;
}).call(this);
