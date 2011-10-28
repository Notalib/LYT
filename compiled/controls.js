(function() {
  var FF, FR, LastNCC, LastPart, NextNCC, NextPart, PlayOrPause;
  PlayOrPause = function() {
    try {
      if (Player.player.paused) {
        Player.isUserEvent = true;
        Player.userPaused = false;
        if (rememberSoundFile.length > 0) {
          GetSound(rememberSoundFile[0], rememberSoundFile[1], rememberSoundFile[2]);
          return rememberSoundFile.length = 0;
        } else {
          return Player.player.play();
        }
      } else {
        Player.isUserEvent = true;
        Player.userPaused = true;
        return Player.player.pause();
      }
    } catch (e) {
      return alert(e.message);
    }
  };
  FF = function() {
    if (Player.player.playbackRate !== undefined) {
      if (Player.player.playbackRate === Player.player.defaultPlaybackRate) {
        try {
          return Player.player.playbackRate = 2;
        } catch (err) {
          return alert("kunne ikke spole frem i dette medie");
        }
      } else {
        try {
          return Player.player.playbackRate = Player.player.defaultPlaybackRate;
        } catch (err) {
          return alert("kunne ikke indstile playbackrate frem i dette medie");
        }
      }
    }
  };
  FR = function() {
    if (Player.player.currentTime !== undefined) {
      try {
        return Player.player.currentTime += -5;
      } catch (err) {
        return alert("kunne ikke spole tilbage i dette medie");
      }
    }
  };
  NextPart = function() {
    var GetAllTheText, aTextTag;
    try {
      clearInterval(Player.BeginPolling);
      Pause();
      if (audioTagList.length > 0) {
        audioTagList.shift();
      }
      if (textTagList.length > 0) {
        aTextTag = textTagList.shift();
        GetAllTheText = false;
        return GetTextAndSoundPiece(aTextTag.getAttribute("id"), smilCacheTable[currentSmilFile]);
      } else {
        if (typeof nextAElement != "undefined" && nextAElement !== null) {
          return GetTextAndSound(nextAElement);
        }
      }
    } catch (e) {
      return alert(e.message);
    }
  };
  LastPart = function() {
    var i, _results;
    try {
      clearInterval(Player.BeginPolling);
      Pause();
      if (textTagList.length === tempTextList.length - 1) {
        if (currentAElement.getAttribute("xhref") === PLAYLIST[0].getAttribute("xhref")) {
          return alert("call GUI to show message - reached start of book");
        } else {
          Player.LastPartNCCJump = true;
          LastNCC();
          i = 0;
          while (i < tempTextList.length) {
            textTagList.shift();
            i++;
          }
          return GetTextAndSoundPiece(tempTextList[tempTextList.length - 1].getAttribute("id"), smilCacheTable[currentSmilFile]);
        }
      } else {
        if (textTagList.length === 0) {
          textTagList.unshift(tempTextList[tempTextList.length - 1]);
          return GetTextAndSoundPiece(tempTextList[tempTextList.length - 2].getAttribute("id"), smilCacheTable[currentSmilFile]);
        } else {
          i = 0;
          _results = [];
          while (i < tempTextList.length) {
            if (textTagList[0] === tempTextList[i]) {
              if (i > 1) {
                textTagList.unshift(tempTextList[i - 1]);
                GetTextAndSoundPiece(tempTextList[i - 2].getAttribute("id"), smilCacheTable[currentSmilFile]);
              }
            }
            _results.push(i++);
          }
          return _results;
        }
      }
    } catch (e) {
      return alert(e.message);
    }
  };
  NextNCC = function() {
    try {
      return GetTextAndSound(nextAElement);
    } catch (e) {
      return alert(e.message);
    }
  };
  LastNCC = function() {
    var temp;
    try {
      temp = GetLastAElement(currentAElement);
      if (temp != null) {
        return GetTextAndSound(temp);
      }
    } catch (e) {
      return alert(e.message);
    }
  };
}).call(this);
