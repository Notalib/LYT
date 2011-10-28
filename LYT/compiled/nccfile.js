(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  __bind(function() {
    var loadCache, parseMetadata, parseStructure;
    this.NCCFile = (function() {
      function NCCFile(url) {
        var cacheLocally, loadLocal, loadRemote;
        this.url = url;
        loadRemote = __bind(function() {
          var options;
          options = {
            url: this.url,
            dataType: "xml",
            async: false,
            cache: false,
            success: __bind(function(xml, status, xhr) {
              xml = jQuery(xml);
              this.structure = parseStructure(xml);
              return this.metadata = parseMetadata(xml);
            }, this)
          };
          return jQuery.ajax(this.url, options);
        }, this);
        cacheLocally = __bind(function() {
          return cache.write("ncc", this.url, this.toJSON());
        }, this);
        loadLocal = __bind(function() {
          var data;
          data = cache.read("ncc", this.url);
          if (!(data && data.structure && data.metadata)) {
            return false;
          }
          this.structure = data.structure;
          this.metadata = data.metadata;
          return true;
        }, this);
        if (!loadLocal()) {
          loadRemote();
        }
      }
      NCCFile.prototype.creators = function() {
        var creator, creators;
        if (this.metadata.creator == null) {
          return ["?"];
        }
        creators = (function() {
          var _i, _len, _ref, _results;
          _ref = this.metadata.creator;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            creator = _ref[_i];
            _results.push(creator.content);
          }
          return _results;
        }).call(this);
        if (creators.length > 1) {
          return creators.slice(0, -1).join(", ") + " & " + creators.pop();
        } else {
          return creators[0];
        }
      };
      NCCFile.prototype.toHTMLList = function() {
        var element, mapper;
        mapper = function(items) {
          var element, item, list, _i, _len;
          list = jQuery("<ol></ol>");
          for (_i = 0, _len = items.length; _i < _len; _i++) {
            item = items[_i];
            element = jQuery("<li></li>");
            element.attr("id", item.id);
            element.attr("xhref", item.href);
            element.text(item.text);
            if (item.children != null) {
              element.append(mapper(item.children));
            }
            list.append(element);
          }
          return list;
        };
        element = jQuery("<ul></ul>");
        element.attr("titel", this.metadata.title.content);
        element.attr("forfatter", this.creators());
        element.attr("totalTime", this.metadata.totalTime.content);
        element.attr("id", "NccRootElement");
        element.attr("data-role", "listview");
        element.append(mapper(this.structure).html());
        return element;
      };
      NCCFile.prototype.toJSON = function() {
        if (!((this.structure != null) && (this.metadata != null))) {
          return null;
        }
        return {
          structure: this.structure,
          metadata: this.metadata,
          timestamp: (new Date).getTime()
        };
      };
      return NCCFile;
    })();
    loadCache = function(url) {};
    parseMetadata = function(xml) {
      var findNodes, found, metadata, selector, selectors, _i, _j, _len, _len2, _ref, _ref2;
      selectors = {
        singular: ["dc:coverage", "dc:date", "dc:description", ["dc:format", "ncc:format"], ["dc:identifier", "ncc:identifier"], "dc:publisher", "dc:relation", "dc:rights", "dc:source", "dc:subject", "dc:title", "dc:type", "ncc:charset", "ncc:depth", "ncc:files", "ncc:footnotes", "ncc:generator", "ncc:kByteSize", "ncc:maxPageNormal", "ncc:multimediaType", "ncc:pageFront", "ncc:page-front", "ncc:pageNormal", "ncc:page-normal", ["ncc:pageSpecial", "ncc:page-special"], "ncc:prodNotes", "ncc:producer", "ncc:producedDate", "ncc:revision", "ncc:revisionDate", ["ncc:setInfo", "ncc:setinfo"], "ncc:sidebars", "ncc:sourceDate", "ncc:sourceEdition", "ncc:sourcePublisher", "ncc:sourceRights", "ncc:sourceTitle", ["ncc:tocItems", "ncc:tocitems"], ["ncc:totalTime", "ncc:totaltime"]],
        plural: ["dc:contributor", "dc:creator", "dc:language", "ncc:narrator"]
      };
      findNodes = function(selectors) {
        var name, nodes, selector;
        if (!(selectors instanceof Array)) {
          selectors = [selectors];
        }
        name = selectors[0].replace(/[^:]+:/, '');
        nodes = [];
        while (selectors.length > 0) {
          selector = "meta[name='" + (selectors.shift()) + "']";
          xml.find(selector).each(function() {
            var node, obj;
            node = jQuery(this);
            obj = {};
            obj.content = node.attr("content");
            if (node.attr("scheme")) {
              obj.scheme = node.attr("scheme");
            }
            return nodes.push(obj);
          });
        }
        if (nodes.length === 0) {
          return null;
        }
        return {
          nodes: nodes,
          name: name
        };
      };
      xml = xml.find("head").first();
      metadata = {};
      _ref = selectors.singular;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        selector = _ref[_i];
        found = findNodes(selector);
        if (found != null) {
          metadata[found.name] = found.nodes.shift();
        }
      }
      _ref2 = selectors.plural;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        selector = _ref2[_j];
        found = findNodes(selector);
        if (found != null) {
          metadata[found.name] = jQuery.makeArray(found.nodes);
        }
      }
      return metadata;
    };
    return parseStructure = function(xml) {
      var getConsecutive, headings, level, structure;
      getConsecutive = function(headings, level, collector) {
        var children, heading, index, link, node, _len;
        for (index = 0, _len = headings.length; index < _len; index++) {
          heading = headings[index];
          if (heading.tagName.toLowerCase() !== ("h" + level)) {
            return index;
          }
          heading = jQuery(heading);
          link = heading.find("a").first();
          node = {
            text: link.text(),
            href: link.attr("href"),
            id: heading.attr("id")
          };
          children = [];
          index += getConsecutive(headings.slice(index + 1), level + 1, children);
          if (children.length > 0) {
            node.children = children;
          }
          collector.push(node);
        }
        return headings.length;
      };
      headings = jQuery.makeArray(xml.find(":header"));
      level = parseInt(headings[0].tagName.slice(1), 10);
      structure = [];
      getConsecutive(headings, level, structure);
      return structure;
    };
  }, this)();
}).call(this);
