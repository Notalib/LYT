/* A simple CoffeeScript dependency manager and concatenator
 * Copyright (c) 2011 Daniel Høier Øhrgaard, Stimulacrum
 * 
 * MIT license
 * 
 */

(function() {
  var exec, fs, path;

  exec = require("child_process").exec;

  path = require("path");

  fs = require("fs");

  exports.grind = function(loadpaths, files) {
    var dependencies, file, loadpath, locate, parse, process, read;
    if (typeof files === "string") files = [files];
    if (typeof loadpaths === "string") loadpaths = [loadpaths];
    dependencies = [];
    loadpaths = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = loadpaths.length; _i < _len; _i++) {
        loadpath = loadpaths[_i];
        _results.push(path.resolve(loadpath));
      }
      return _results;
    })();
    locate = function(file) {
      var loadpath, resolved, _i, _len;
      if (!/\.coffee$/.test(file)) file = "" + file + ".coffee";
      if (path.existsSync(file)) return path.resolve(file);
      for (_i = 0, _len = loadpaths.length; _i < _len; _i++) {
        loadpath = loadpaths[_i];
        resolved = path.join(loadpath, file);
        if (path.existsSync(resolved)) return resolved;
      }
      throw "Could not find " + file + " in the given loadpath(s)";
    };
    process = function(items, chain) {
      var file, _i, _len, _results;
      if (chain == null) chain = [];
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        file = items[_i];
        if (!(dependencies.indexOf(file) === -1)) continue;
        if (chain.indexOf(file) !== -1) {
          throw "Circular dependency\n" + (chain.join("\n")) + "\n" + file + ")";
        }
        _results.push(read(file, chain));
      }
      return _results;
    };
    read = function(file, chain) {
      var contents, required;
      chain = chain.concat(file);
      contents = fs.readFileSync(file, "utf8");
      required = parse(contents, path.dirname(file));
      process(required, chain);
      return dependencies.push(file);
    };
    parse = function(string, base) {
      var required;
      required = [];
      string.replace(/^#\s*Requires\s*`?(.*?)`?\s*$/igm, function(line, file) {
        if (!/\.coffee$/.test(file)) file = "" + file + ".coffee";
        if (/^\//.test(file)) {
          required.push(locate(file));
        } else {
          required.push(path.join(base, file));
        }
        return line;
      });
      return required;
    };
    if (files == null) {
      files = walk();
    } else {
      files = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = files.length; _i < _len; _i++) {
          file = files[_i];
          _results.push(locate(file));
        }
        return _results;
      })();
    }
    process(files);
    return dependencies;
  };

}).call(this);
