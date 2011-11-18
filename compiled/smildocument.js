(function() {
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  (function() {
    var parseMainSequence, parseNPT;
    LYT.SMILDocument = (function() {
      __extends(SMILDocument, LYT.DTBDocument);
      function SMILDocument(url) {
        SMILDocument.__super__.constructor.call(this, url, __bind(function(deferred) {
          var mainSequence;
          mainSequence = this.xml.find("body > seq:first");
          this.duration = parseFloat(mainSequence.attr("dur")) || 0;
          return this.pars = parseMainSequence(mainSequence);
        }, this));
      }
      SMILDocument.prototype.getParByTime = function(offset) {
        var par, _i, _len, _ref;
        if (offset == null) {
          offset = 0;
        }
        _ref = this.pars;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          par = _ref[_i];
          if ((par.start <= offset && offset < par.end)) {
            return par;
          }
        }
        return null;
      };
      return SMILDocument;
    })();
    parseMainSequence = function(sequence) {
      var pars;
      pars = [];
      sequence.children("par").each(function() {
        var audio, par, text;
        par = jQuery(this);
        audio = par.find("audio:first");
        text = par.find("text:first");
        return pars.push({
          id: par.attr("id"),
          start: parseNPT(audio.attr("clip-begin")),
          end: parseNPT(audio.attr("clip-end")),
          audio: {
            id: audio.attr("id"),
            src: audio.attr("src")
          },
          text: {
            id: text.attr("id"),
            src: text.attr("src")
          }
        });
      });
      return pars;
    };
    return parseNPT = function(string) {
      var time;
      time = string.match(/^npt=([\d.]+)s?$/i);
      return parseFloat(time != null ? time[1] : void 0) || 0;
    };
  })();
}).call(this);
