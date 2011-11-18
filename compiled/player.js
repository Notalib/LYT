(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  LYT.player = {
    ready: false,
    jplayer: null,
    el: null,
    media: null,
    time: "",
    book: null,
    setup: __bind(function() {
      this.el = jQuery("#jplayer");
      return this.jplayer = this.el.jPlayer({
        ready: __bind(function() {
          return this.ready = True;
        }, this),
        swfPath: "/assets/lib/jPlayer/",
        supplied: "mp3",
        solution: 'html, flash'
      });
    }, this),
    pause: __bind(function() {
      return this.jplayer('pause');
    }, this),
    stop: __bind(function() {
      this.jplayer('stop');
      return this.jplayer('clearmedia');
    }, this),
    play: __bind(function(time) {
      if (!(time != null)) {
        return this.jplayer('play');
      } else {
        return this.jplayer('play', time);
      }
    }, this),
    update: __bind(function(time) {
      this.time = time;
      if (!(this.media != null)) {
        this.book.mediaFor().done(__bind(function(media) {
          if (!(media != null)) {
            return this.media = media;
          } else {
            ;
          }
        }, this));
      } else if (this.media.end < this.time) {
        this.book.mediaFor(this.section, this.time).done(__bind(function(media) {
          if (!(media != null)) {
            if (this.media.audio === !media.audio) {
              this.jplayer('setmedia', media);
              this.play();
            }
            return this.media = media;
          }
        }, this));
      }
      if (this.currentTranscript.end < this.currentTime) {
        return log('hide transcript');
      } else if (this.currentTranscript.start >= this.currentTime) {
        return log('show transcript');
      }
    }, this),
    loadBook: __bind(function(book, section, offset) {
      if (this.ready) {
        this.book = book;
        return this.el.bind(jQuery.jPlayer.event.timeupdate, __bind(function(event) {
          return this.update(event.jPlayer.status.currentTime);
        }, this));
      }
    }, this),
    nextPart: function() {
      this.stop();
      return this.load();
    },
    previousPart: function() {
      this.stop();
      return this.load();
    }
  };
}).call(this);
