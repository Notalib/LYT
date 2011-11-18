(function() {
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  LYT.TextContentDocument = (function() {
    function TextContentDocument() {
      TextContentDocument.__super__.constructor.apply(this, arguments);
    }
    __extends(TextContentDocument, LYT.DTBDocument);
    TextContentDocument.prototype.getTextById = function(id) {
      var text;
      text = this.xml.find("#" + id).first().text();
      return jQuery.trim(text);
    };
    return TextContentDocument;
  })();
}).call(this);
