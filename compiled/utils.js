(function() {
  var __slice = Array.prototype.slice;
  this.log = (function() {
    var console;
    console = window.console || {};
    return {
      message: function() {
        var messages;
        messages = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (!(LYT.config.logging > 1)) {
          return;
        }
        return typeof console.log == "function" ? console.log.apply(console, messages) : void 0;
      },
      error: function() {
        var messages, method;
        messages = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (!(LYT.config.logging > 0)) {
          return;
        }
        method = console.error || console.log;
        return method != null ? method.apply(console, messages) : void 0;
      },
      info: function() {
        var messages;
        messages = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (!(LYT.config.logging > 1)) {
          return;
        }
        return (console.info || this.message).apply(console, messages);
      },
      group: function() {
        var message, messages, method, title, _i, _len;
        title = arguments[0], messages = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        if (title == null) {
          title = "";
        }
        if (!(LYT.config.logging > 1)) {
          return;
        }
        method = console.groupCollapsed || console.group;
        if (method != null) {
          method.call(console, title);
        } else {
          this.message("=== " + title + " ===");
        }
        if (messages.length > 0) {
          for (_i = 0, _len = messages.length; _i < _len; _i++) {
            message = messages[_i];
            this.message(message);
          }
          return this.closeGroup();
        }
      },
      errorGroup: function() {
        var message, messages, method, title, _i, _len;
        title = arguments[0], messages = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        if (title == null) {
          title = "";
        }
        if (!(LYT.config.logging > 0)) {
          return;
        }
        method = console.groupCollapsed || console.group;
        if (method != null) {
          method.call(console, title);
        } else {
          this.error("=== " + title + " ===");
        }
        if (messages.length > 0) {
          for (_i = 0, _len = messages.length; _i < _len; _i++) {
            message = messages[_i];
            this.error(message);
          }
          return this.closeGroup();
        }
      },
      closeGroup: function() {
        return (console.groupEnd || this.message).call(console, "=== *** ===");
      },
      trace: function() {
        if (!(LYT.config.logging > 0)) {
          return;
        }
        return typeof console.trace == "function" ? console.trace() : void 0;
      }
    };
  })();
  this.formatTime = function(seconds) {
    var hours, minutes;
    seconds = parseInt(seconds, 10);
    if (!seconds || seconds < 0) {
      seconds = 0;
    }
    hours = (seconds / 3600) >>> 0;
    minutes = "0" + (((seconds % 3600) / 60) >>> 0);
    seconds = "0" + (seconds % 60);
    return "" + hours + ":" + (minutes.slice(-2)) + ":" + (seconds.slice(-2));
  };
  this.parseTime = function(string) {
    var component, components;
    components = String(string).match(/^(\d*):?(\d{2}):(\d{2})$/);
    if (components == null) {
      return 0;
    }
    components.shift();
    components = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = components.length; _i < _len; _i++) {
        component = components[_i];
        _results.push(parseInt(component, 10) || 0);
      }
      return _results;
    })();
    return components[0] * 3600 + components[1] * 60 + components[2];
  };
  this.toSentence = function(array) {
    if (!(array instanceof Array)) {
      return "";
    }
    if (array.length === 1) {
      return String(array[0]);
    }
    return "" + (array.slice(0, -1).join(", ")) + " & " + (array.slice(-1));
  };
}).call(this);
