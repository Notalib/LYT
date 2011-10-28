(function() {
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty;
  this.rpc = (function() {
    var soapTemplate;
    soapTemplate = '<?xml version="1.0" encoding="UTF-8"?>\
    <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns1="http://www.daisy.org/ns/daisy-online/">\
    <SOAP-ENV:Body>#{body}</SOAP-ENV:Body>\
    </SOAP-ENV:Envelope>';
    return function() {
      var action, args, handlers, options, soap, xml;
      action = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (typeof action !== "string") {
        throw new TypeError;
      }
      if (protocol[action] == null) {
        throw "RPC: Action \"" + action + "\" not found";
      }
      handlers = protocol[action];
      options = jQuery.extend({}, config.rpc.options);
      soap = (typeof handlers.request === "function" ? handlers.request.apply(handlers, args) : void 0) || null;
      if (typeof soap !== "object") {
        soap = null;
      }
      xml = {};
      xml[action] = soap;
      xml = rpc.toXML(xml);
      xml = xml !== "" ? "<ns1:" + action + ">" + xml + "</ns1:" + action + ">" : "<ns1:" + action + " />";
      options.data = soapTemplate.replace(/#\{body\}/, xml);
      log.group("RPC: Calling \"" + action + "\"", soap, options.data);
      options.success = function(data, status, xhr) {
        var $xml;
        $xml = jQuery(data);
        if ($xml.find("faultstring").text().match(errorRegExp)) {
          log.group("RPC: Error: Invalid/uninitialized session");
          log.message(data);
          log.closeGroup();
          return eventSystemNotLoggedIn();
        } else {
          log.group("RPC: Response for action \"" + action + "\"");
          log.message(data);
          log.closeGroup();
          if (handlers.receive != null) {
            return handlers.receive($xml, data, status, xhr);
          }
        }
      };
      if (handlers.complete != null) {
        options.complete = handlers.complete;
      }
      options.error = handlers.error || rpc.error;
      return jQuery.ajax(options);
    };
  })();
  this.rpc.toXML = function(hash) {
    var item, key, type, value, xml, _i, _len;
    if (hash == null) {
      return "";
    }
    xml = "";
    type = typeof hash;
    if (type === "string" || type === "number" || type === "boolean") {
      hash = String(hash).replace(/&(?![a-z0-9]+;)/gi, "&amp;");
      hash = hash.replace(/</g, "&lt;");
      hash = hash.replace(/>/g, "&gt;");
      return hash;
    }
    if (type === "object") {
      for (key in hash) {
        if (!__hasProp.call(hash, key)) continue;
        value = hash[key];
        key = rpc.toXML(key);
        if (value instanceof Array) {
          for (_i = 0, _len = value.length; _i < _len; _i++) {
            item = value[_i];
            xml += "<ns1:" + key + ">" + (rpc.toXML(item)) + "</ns1:" + key + ">";
          }
        } else {
          xml += "<ns1:" + key + ">" + (rpc.toXML(value)) + "</ns1:" + key + ">";
        }
      }
    }
    return xml;
  };
  this.rpc.error = (function() {
    var errorRegExp;
    errorRegExp = /session (is (invalid|uninitialized)|has not been initialized)/i;
    return function(xhr, error, exception) {
      var title;
      title = "ERROR: RPC: ";
      if (xhr.status > 399) {
        title += xhr.status;
      } else if (exception === "timeout") {
        alert("Ups - vi misted forbindelsen. Måske har du ingen forbindelse til Internettet?");
        title += "Timed out";
      } else if (xhr.responseText.match(errorRegExp)) {
        eventSystemNotLoggedIn();
        title += "Invalid/uninitialized session";
      } else {
        title += "General error";
      }
      log.errorGroup(title);
      log.error(xhr);
      log.error("Error:", error);
      log.error("Exception:", exception);
      log.error("Response: ", xhr.responseText);
      return log.closeGroup();
    };
  })();
}).call(this);
