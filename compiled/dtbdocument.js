(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty;
  (function() {
    var METADATA_NAMES;
    METADATA_NAMES = {
      singular: {
        coverage: "dc:coverage",
        date: "dc:date",
        description: "dc:description",
        format: ["dc:format", "ncc:format"],
        identifier: ["dc:identifier", "ncc:identifier"],
        publisher: "dc:publisher",
        relation: "dc:relation",
        rights: "dc:rights",
        source: "dc:source",
        subject: "dc:subject",
        title: "dc:title",
        type: "dc:type",
        charset: "ncc:charset",
        depth: "ncc:depth",
        files: "ncc:files",
        footnotes: "ncc:footnotes",
        generator: "ncc:generator",
        kByteSize: "ncc:kByteSize",
        maxPageNormal: "ncc:maxPageNormal",
        multimediaType: "ncc:multimediaType",
        pageFront: ["ncc:pageFront", "ncc:page-front"],
        pageNormal: ["ncc:pageNormal", "ncc:page-normal"],
        pageSpecial: ["ncc:pageSpecial", "ncc:page-special"],
        prodNotes: "ncc:prodNotes",
        producer: "ncc:producer",
        producedDate: "ncc:producedDate",
        revision: "ncc:revision",
        revisionDate: "ncc:revisionDate",
        setInfo: ["ncc:setInfo", "ncc:setinfo"],
        sidebars: "ncc:sidebars",
        sourceDate: "ncc:sourceDate",
        sourceEdition: "ncc:sourceEdition",
        sourcePublisher: "ncc:sourcePublisher",
        sourceRights: "ncc:sourceRights",
        sourceTitle: "ncc:sourceTitle",
        tocItems: ["ncc:tocItems", "ncc:tocitems", "ncc:TOCitems"],
        totalTime: ["ncc:totalTime", "ncc:totaltime"]
      },
      plural: {
        contributor: "dc:contributor",
        creator: "dc:creator",
        language: "dc:language",
        narrator: "ncc:narrator"
      }
    };
    return LYT.DTBDocument = (function() {
      function DTBDocument(url, callback) {
        var deferred, failed, loaded, ready, recover, reject, resolve;
        this.url = url;
        deferred = jQuery.Deferred();
        deferred.promise(this);
        this.xml = null;
        resolve = __bind(function(document) {
          this.xml = jQuery(document);
          if (typeof callback == "function") {
            callback(deferred);
          }
          return deferred.resolve(this);
        }, this);
        reject = __bind(function(status, error) {
          return deferred.reject(status, error);
        }, this);
        recover = function(jqXHR, status) {
          var content, html;
          log.message("DTBDocument: Received invalid XML. Attempting recovery");
          content = jqXHR.responseText.match(/<html[^>]*>([\s\S]+)<\/html>\s*$/i);
          if ((content != null) && content[1]) {
            html = jQuery("<html></html>");
            html.html(content[1]);
            if (html.find("body").length !== 0) {
              log.message("DTBDocument: Recovery succeeded");
              resolve(html);
              return true;
            }
          } else {
            log.message("DTBDocument: Recovery failed");
          }
          return false;
        };
        ready = __bind(function(document) {
          this.xml = jQuery(document);
          if (typeof callback == "function") {
            callback(deferred);
          }
          return deferred.resolve(this);
        }, this);
        loaded = __bind(function(xml, status, jqXHR) {
          log.group("DTB: Got: " + this.url, xml);
          if (jQuery(xml).find("parsererror").length > 0) {
            return recover(jqXHR, status) || reject;
          } else {
            return ready(xml);
          }
        }, this);
        failed = __bind(function(jqXHR, status, error) {
          if (status === "parsererror") {
            if (recover(jqXHR, status)) {
              return;
            }
          }
          log.errorGroup("DTB: Failed to get " + this.url, jqXHR, status, error);
          return reject(status, error);
        }, this);
        log.message("DTB: Getting: " + this.url);
        jQuery.ajax({
          url: this.url,
          dataType: "xml",
          async: true,
          cache: true,
          success: loaded,
          error: failed
        });
      }
      DTBDocument.prototype.getMetadata = function() {
        var findNodes, found, metadata, name, values, xml, _ref, _ref2;
        if (this.xml == null) {
          return {};
        }
        findNodes = __bind(function(values) {
          var nodes, selectors, value;
          if (!(values instanceof Array)) {
            values = [values];
          }
          nodes = [];
          selectors = ((function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = values.length; _i < _len; _i++) {
              value = values[_i];
              _results.push("meta[name='" + value + "']");
            }
            return _results;
          })()).join(", ");
          this.xml.find(selectors).each(function() {
            var node;
            node = jQuery(this);
            return nodes.push({
              content: node.attr("content"),
              scheme: node.attr("scheme") || null
            });
          });
          if (nodes.length === 0) {
            return null;
          }
          return nodes;
        }, this);
        xml = this.xml.find("head").first();
        metadata = {};
        _ref = METADATA_NAMES.singular;
        for (name in _ref) {
          if (!__hasProp.call(_ref, name)) continue;
          values = _ref[name];
          found = findNodes(values);
          if (found != null) {
            metadata[name] = found.shift();
          }
        }
        _ref2 = METADATA_NAMES.plural;
        for (name in _ref2) {
          if (!__hasProp.call(_ref2, name)) continue;
          values = _ref2[name];
          found = findNodes(values);
          if (found != null) {
            metadata[name] = found;
          }
        }
        return metadata;
      };
      return DTBDocument;
    })();
  })();
}).call(this);
