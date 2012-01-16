/* A simple Node.js modeule for validating HTML and CSS through
 * W3C's validation services
 * Copyright (c) 2011 Daniel Høier Øhrgaard, Stimulacrum
 * 
 * MIT license
 * 
 */

(function() {
  var multipartRequest, w3validation;
  var __hasProp = Object.prototype.hasOwnProperty;

  multipartRequest = function(options, callback) {
    var boundary, http, request, _end;
    http = require("http");
    boundary = "----------------------------" + ((new Date).getTime());
    options.method = "POST";
    options.headers || (options.headers = {});
    options.headers["Content-Type"] = "multipart/form-data; boundary=" + boundary;
    request = http.request(options, callback);
    request.addParam = function(name, value) {
      request.write("--" + boundary + "\r\n");
      request.write("Content-Disposition: form-data; name=\"" + name + "\"\r\n\r\n");
      return request.write("" + value + "\r\n");
    };
    request.addParams = function(hash) {
      var name, value, _results;
      _results = [];
      for (name in hash) {
        if (!__hasProp.call(hash, name)) continue;
        value = hash[name];
        _results.push(request.addParam(name, value));
      }
      return _results;
    };
    request.addFile = function(name, path, mimetype, encoding) {
      var content;
      try {
        content = require("fs").readFileSync(path, encoding);
        request.write("--" + boundary + "\r\n");
        request.write("Content-Disposition: form-data; name=\"" + name + "\"; filename=\"" + (require("path").basename(path)) + "\"\r\n");
        request.write("Content-Type: " + mimetype + "\r\n\r\n");
        return request.write("" + content + "\r\n");
      } catch (error) {
        throw error;
      }
    };
    _end = request.end.bind(request);
    request.end = function() {
      return _end("--" + boundary + "--\r\n");
    };
    return request;
  };

  w3validation = function(url, callback) {
    var options, request;
    url = require("url").parse(url);
    options = {
      host: url.hostname,
      post: 80,
      path: url.pathname
    };
    request = multipartRequest(options);
    request.addParam("output", "soap12");
    return request.on("response", function(response) {
      var errors, soap, status, warnings;
      if (response.statusCode !== 200) {
        if (typeof callback === "function") callback(response.statusCode);
        return;
      }
      response.setEncoding("utf8");
      status = response.headers["x-w3c-validator-status"];
      errors = [];
      warnings = [];
      soap = "";
      response.on("data", function(chunk) {
        return soap += chunk;
      });
      return response.on("end", function() {
        soap.replace(/<m:error>([\s\S]*?)<\/m:error>/gi, function(string) {
          return errors.push(string);
        });
        soap.replace(/<m:warning>([\s\S]*?)<\/m:warning>/gi, function(string) {
          return warnings.push(string);
        });
        return typeof callback === "function" ? callback(null, status, errors, warnings) : void 0;
      });
    });
  };

  exports.validateHTML = function(path, callback) {
    var receiver, request;
    receiver = function(err, status, errors, warnings) {
      var error, parse, warning, _i, _j, _len, _len2;
      if (err != null) throw err;
      parse = function(type, string) {
        var rgx;
        rgx = /^[\s\S]*<m:line>(\d+)<\/m:line>[\s\S]*<m:col>(\d+)<\/m:col>[\s\S]*<m:message>(.+?)<\/m:message>[\s\S]*$/i;
        return string.replace(rgx, function(m, line, col, message) {
          return console.log("" + type + ": Line " + line + ":" + col + ": " + message + "\n");
        });
      };
      console.log("Result: " + status);
      for (_i = 0, _len = errors.length; _i < _len; _i++) {
        error = errors[_i];
        parse("Error", error);
      }
      for (_j = 0, _len2 = warnings.length; _j < _len2; _j++) {
        warning = warnings[_j];
        parse("Warning", warning);
      }
      return typeof callback === "function" ? callback() : void 0;
    };
    request = w3validation("http://validator.w3.org/check", receiver);
    request.addFile("uploaded_file", path, "text/html", "utf-8");
    request.end();
    return console.log("Contacting validator.w3c.org ...");
  };

  exports.validateCSS = function(path, callback) {
    var receiver, request;
    receiver = function(err, status, errors, warnings) {
      var cleanup, error, parse, warning, _i, _j, _len, _len2;
      if (err != null) throw err;
      cleanup = function(string) {
        string = string.trim().replace(/^([\s\S]*)\((http[^\)]+)\)([\s\S]*)$/g, "$1$3\n$2");
        string = string.trim().replace(/\s\s+/g, ' ');
        string = string.trim().replace(/\s+:/g, ':');
        return string = string.trim().replace(/\s*:\s*$/g, '');
      };
      parse = function(type, string) {
        var rgx;
        rgx = /^[\s\S]*<m:line>(\d+)<\/m:line>[\s\S]*<m:context>\s*(\S[\s\S]+)\s*<\/m:context>[\s\S]*<m:message>\s*(\S[\s\S]+)\s*<\/m:message>[\s\S]*$/i;
        return string.replace(rgx, function(src, line, context, message) {
          return console.log("" + type + ": Line " + line + ", in \"" + (context.trim()) + "\"\n" + (cleanup(message)) + "\n");
        });
      };
      console.log("Result: " + status);
      for (_i = 0, _len = errors.length; _i < _len; _i++) {
        error = errors[_i];
        parse("Error", error);
      }
      for (_j = 0, _len2 = warnings.length; _j < _len2; _j++) {
        warning = warnings[_j];
        parse("Warning", warning);
      }
      return typeof callback === "function" ? callback() : void 0;
    };
    request = w3validation("http://jigsaw.w3.org/css-validator/validator", receiver);
    request.addFile("file", path, "text/css", "utf-8");
    request.addParams({
      profile: "mobile",
      usermedium: "all",
      warning: "2"
    });
    request.end();
    return console.log("Contacting jigsaw.w3c.org ...");
  };

}).call(this);
