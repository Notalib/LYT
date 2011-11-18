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
    var NCCSection, parseStructure;
    LYT.NCCDocument = (function() {
      __extends(NCCDocument, LYT.TextContentDocument);
      function NCCDocument(url) {
        NCCDocument.__super__.constructor.call(this, url, __bind(function(deferred) {
          return this.structure = parseStructure(this.xml);
        }, this));
      }
      NCCDocument.prototype.findSection = function(id) {
        var find;
        if (id == null) {
          id = null;
        }
        find = function(id, sections) {
          var child, section, _i, _len;
          for (_i = 0, _len = sections.length; _i < _len; _i++) {
            section = sections[_i];
            if (section.id === id) {
              return section;
            } else if (section.children != null) {
              child = find(id, section.children);
              if (child != null) {
                return child;
              }
            }
          }
          return null;
        };
        if (!id) {
          return this.structure[0] || null;
        }
        return find(id, this.structure);
      };
      return NCCDocument;
    })();
    NCCSection = (function() {
      function NCCSection(heading) {
        var anchor;
        heading = jQuery(heading);
        this.id = heading.attr("id");
        this["class"] = heading.attr("class");
        anchor = heading.find("a:first");
        this.title = jQuery.trim(anchor.text());
        this.url = anchor.attr("href");
        this.children = [];
      }
      NCCSection.prototype.flatten = function() {
        var child, flat, _i, _len, _ref;
        flat = [this];
        _ref = this.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          flat = flat.concat(child.flatten());
        }
        return flat;
      };
      return NCCSection;
    })();
    return parseStructure = function(xml) {
      var getConsecutive, headings, level, structure;
      getConsecutive = function(headings, level, collector) {
        var heading, index, section, _len;
        for (index = 0, _len = headings.length; index < _len; index++) {
          heading = headings[index];
          if (heading.tagName.toLowerCase() !== ("h" + level)) {
            return index;
          }
          section = new NCCSection(heading);
          index += getConsecutive(headings.slice(index + 1), level + 1, section.children);
          collector.push(section);
        }
        return headings.length;
      };
      structure = [];
      headings = jQuery.makeArray(xml.find(":header"));
      if (headings.length === 0) {
        return [];
      }
      level = parseInt(headings[0].tagName.slice(1), 10);
      getConsecutive(headings, level, structure);
      return structure;
    };
  })();
}).call(this);
