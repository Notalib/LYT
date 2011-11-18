(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty;
  LYT.Book = (function() {
    function Book(id) {
      var deferred, getNCC, getResources, issue;
      this.id = id;
      deferred = jQuery.Deferred();
      deferred.promise(this);
      this.resources = {};
      this.nccDocument = null;
      issue = __bind(function() {
        var issued;
        issued = LYT.service.issue(this.id);
        issued.then(getResources);
        return issued.fail(function() {
          return deferred.reject();
        });
      }, this);
      getResources = __bind(function() {
        var got;
        got = LYT.service.getResources(this.id);
        got.fail(function() {
          return deferred.reject();
        });
        return got.then(__bind(function(resources) {
          var localUri, ncc, uri, _ref;
          this.resources = resources;
          ncc = null;
          _ref = this.resources;
          for (localUri in _ref) {
            if (!__hasProp.call(_ref, localUri)) continue;
            uri = _ref[localUri];
            this.resources[localUri] = {
              url: uri,
              document: null
            };
            if (localUri.match(/^ncc\.html?$/i)) {
              ncc = this.resources[localUri];
            }
          }
          if (ncc != null) {
            return getNCC(ncc);
          } else {
            return deferred.reject();
          }
        }, this));
      }, this);
      getNCC = __bind(function(obj) {
        var ncc;
        ncc = new LYT.NCCDocument(obj.url);
        ncc.fail(function() {
          return deferred.reject();
        });
        return ncc.then(__bind(function(document) {
          obj.document = this.nccDocument = document;
          return deferred.resolve(this);
        }, this));
      }, this);
      issue(this.id);
    }
    Book.prototype.preloadSection = function(section) {
      var deferred, documents, file, section, sections, url, _i, _len, _ref;
      if (section == null) {
        section = null;
      }
      deferred = jQuery.Deferred();
      section = this.nccDocument.findSection(section);
      if (section == null) {
        deferred.reject(null);
        return;
      }
      sections = section.flatten();
      for (_i = 0, _len = sections.length; _i < _len; _i++) {
        section = sections[_i];
        if (!section.document) {
          file = section.url.replace(/#.*$/, "");
          url = (_ref = this.resources[file]) != null ? _ref.url : void 0;
          if (url == null) {
            deferred.reject(null);
            return;
          }
          if (this.resources[file].document == null) {
            this.resources[file].document = new LYT.SMILDocument(url);
            section.document = this.resources[file].document;
          }
        }
      }
      documents = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = sections.length; _i < _len; _i++) {
          section = sections[_i];
          _results.push(section.document);
        }
        return _results;
      })();
      jQuery.when.apply(null, documents).then(function() {
        return deferred.resolve(sections).fail(function() {
          return deferred.reject(null);
        });
      });
      return deferred;
    };
    Book.prototype.mediaFor = function(section, offset) {
      var deferred, preload;
      if (section == null) {
        section = null;
      }
      if (offset == null) {
        offset = null;
      }
      deferred = jQuery.Deferred();
      preload = this.preloadSection(section);
      preload.fail(function() {
        return deferred.resolve(null);
      });
      preload.done(__bind(function(sections) {
        var media, par, section, txtfile, txtid, _i, _len, _ref, _ref2, _ref3, _ref4;
        offset = offset || 0;
        for (_i = 0, _len = sections.length; _i < _len; _i++) {
          section = sections[_i];
          par = section.document.getParByTime(offset);
          if (par) {
            media = {
              section: section.id,
              start: par.start,
              end: par.end
            };
            if (((_ref = par.audio) != null ? _ref.src : void 0) != null) {
              media.audio = ((_ref2 = this.resources[par.audio.src]) != null ? _ref2.url : void 0) || null;
            }
            _ref4 = ((_ref3 = par.text) != null ? _ref3.src : void 0) != null ? par.text.src.split("#") : [null, null], txtfile = _ref4[0], txtid = _ref4[1];
            if ((txtfile != null) && this.resources[txtfile]) {
              if (!this.resources[txtfile].document) {
                this.resources[txtfile].document = new LYT.TextContentDocument(this.resources[txtfile].url);
              }
              this.resources[txtfile].document.done(__bind(function() {
                media.text = this.resources[txtfile].document.getTextById(txtid);
                return deferred.resolve(media);
              }, this));
              this.resources[txtfile].document.fail(__bind(function() {
                media.text = null;
                return deferred.resolve(media);
              }, this));
            } else {
              media.text = null;
              deferred.resolve(media);
            }
            return deferred;
          }
        }
        return deferred.resolve(null);
      }, this));
      return deferred;
    };
    return Book;
  })();
}).call(this);
