/* A very, very simple CoffeeScript concatenator/dependency resolver
 * Copyright (c) 2012 Daniel Høier Øhrgaard, Stimulacrum
 * 
 * MIT license
 * 
 * Usage:
 * 
 *     concat loadpath, file, callback
 * 
 * `loadpath` and `file` can be strings or arrays of strings
 * specifying file paths.  
 * The `callback` will receive 2 arguments `dependencies` and
 * `result`. The former is an array of file paths in their required
 * order, and the second is the concatenated file contents.  
 * In case of an error, `concat` will throw an exception.
 * 
 * The syntax for requiring a file is intended to be simple and
 * documentation-friendly (particularly Docco-friendly).
 * 
 * A dependency declaration is simply a comment line (beginning in
 * the first column) that says "Requires" followed by the file.  
 * Example:
 * 
 *     # Requires `foo/bar.coffee`
 * 
 * The backticks and the `.coffee` extension are both optional:
 * 
 *     # Requires foo/bar
 * 
 * The example uses a filepath that's _relative to the current file_
 * (i.e. if the declaration is in file `x/y/baz.coffee`, it'll
 * include `x/y/foo/bar.coffee`).
 * 
 * To include a file _relative to a loadpath_, use a leading forward
 * slash:
 * 
 *     # Requires /foo/bar
 * 
 * If, for instance, a loadpath is `src/coffee`, the path of the
 * required file will be `src/coffee/foo/bar`
 */

(function() {
  var exec, fs, path;

  exec = require("child_process").exec;

  path = require("path");

  fs = require("fs");

  exports.concat = function(loadpaths, files, callback) {
    var dependencies, file, loadpath, locate, parse, process, read, result;
    if (typeof files === "string") files = [files];
    if (typeof loadpaths === "string") loadpaths = [loadpaths];
    dependencies = [];
    result = "";
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
      dependencies.push(file);
      return result += contents + "\n\n";
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
    return callback(dependencies, result);
  };

}).call(this);
