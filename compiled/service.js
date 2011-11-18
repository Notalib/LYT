(function() {
  LYT.service = {
    logOn: function(username, password) {
      var deferred, failed, gotServiceAnnouncements, gotServiceAttrs, loggedOn, operations, readingSystemAttrsSet;
      deferred = jQuery.Deferred();
      operations = null;
      failed = function(code, message) {
        return deferred.reject(code, message);
      };
      loggedOn = function(success) {
        return LYT.rpc("getServiceAttributes").done(gotServiceAttrs).fail(failed);
      };
      gotServiceAttrs = function(ops) {
        operations = ops;
        return LYT.rpc("setReadingSystemAttributes").done(readingSystemAttrsSet).fail(failed);
      };
      readingSystemAttrsSet = function() {
        deferred.resolve();
        if (operations.indexOf("SERVICE_ANNOUNCEMENTS") !== -1) {
          return LYT.rpc("getServiceAnnouncements").done(gotServiceAnnouncements);
        }
      };
      gotServiceAnnouncements = function(announcements) {};
      LYT.rpc("logOn", username, password).done(loggedOn).fail(failed);
      return deferred;
    },
    logOff: function() {
      return LYT.rpc("logOff");
    },
    issue: function(bookId) {
      return LYT.rpc("issueContent", bookId);
    },
    "return": function(bookId) {
      return LYT.rpc("returnContent", bookId);
    },
    getMetadata: function(bookId) {
      return LYT.rpc("getContentMetadata", bookId);
    },
    getResources: function(bookId) {
      return LYT.rpc("getContentResources", bookId);
    },
    getBookshelf: function(from, to) {
      var deferred;
      if (from == null) {
        from = 0;
      }
      if (to == null) {
        to = -1;
      }
      deferred = jQuery.Deferred();
      LYT.rpc("getContentList", "issued", from, to).then(function(list) {
        var item, _i, _len, _ref, _ref2;
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          item = list[_i];
          _ref2 = ((_ref = item.label) != null ? _ref.split("$") : void 0) || ["", ""], item.author = _ref2[0], item.title = _ref2[1];
          delete item.label;
        }
        return deferred.resolve(list);
      }).fail(function() {
        return deferred.reject();
      });
      return deferred;
    },
    search: function(query) {}
  };
}).call(this);
