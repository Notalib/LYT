(function() {
  LYT.protocol = {
    logOn: {
      request: function(username, password) {
        return {
          username: username,
          password: password
        };
      },
      receive: function($xml, data) {
        return $xml.find("logOnResult").text() === "true" || RPC_ERROR;
      }
    },
    logOff: {
      receive: function($xml, data) {
        return $xml.find("logOffResult").text() === "true" || RPC_ERROR;
      }
    },
    getServiceAttributes: {
      receive: function($xml, data) {
        var operations;
        operations = [];
        $xml.find("supportedOptionalOperations > operation").each(function() {
          return operations.push($(this).text());
        });
        return [operations];
      }
    },
    setReadingSystemAttributes: {
      request: function() {
        return LYT.config.protocol.readingSystemAttributes;
      },
      receive: function($xml, data) {
        return $xml.find("setReadingSystemAttributesResult").text() === "true" || RPC_ERROR;
      }
    },
    getServiceAnnouncements: {
      receive: function($xml, data) {
        var announcements;
        announcements = [];
        $xml.find("announcements > announcement").each(function() {
          var announcement;
          announcement = jQuery(this);
          return announcements.push({
            text: announcement.find("text").text(),
            id: announcement.attr("id")
          });
        });
        return [announcements];
      }
    },
    markAnnouncementsAsRead: {
      request: function(id) {
        return {
          read: {
            item: id
          }
        };
      }
    },
    getContentList: {
      request: function(listID, firstItem, lastItem) {
        return {
          id: listID,
          firstItem: firstItem,
          lastItem: lastItem
        };
      },
      receive: function($xml, data) {
        var items;
        items = [];
        $xml.find("contentItem").each(function() {
          var item;
          item = jQuery(this);
          return items.push({
            id: item.attr("id"),
            label: item.find("label > text").text()
          });
        });
        return [items];
      }
    },
    issueContent: {
      request: function(bookID) {
        return {
          contentID: bookID
        };
      },
      receive: function($xml) {
        return $xml.find('issueContentResult').text() === "true" || RPC_ERROR;
      }
    },
    returnContent: {
      request: function(bookID) {
        return {
          contentID: bookID
        };
      },
      receive: function($xml) {
        return $xml.find("returnContentResult").text() === "true" || RPC_ERROR;
      }
    },
    getContentMetadata: {
      request: function(bookID) {
        return {
          contentID: bookID
        };
      }
    },
    getContentResources: {
      request: function(bookID) {
        return {
          contentID: bookID
        };
      },
      receive: function($xml, data) {
        var resources;
        resources = {};
        $xml.find("resource").each(function() {
          return resources[jQuery(this).attr("localURI")] = jQuery(this).attr("uri");
        });
        return resources;
      }
    },
    setBookmarks: {
      request: function(bookID, bookmarkData) {
        return {
          contentID: bookID,
          bookmarkSet: {
            title: {
              text: bookID,
              audio: ""
            },
            uid: bookID,
            lastmark: {
              ncxref: "xyub00066",
              URI: "cddw000A.smil#xyub00066",
              timeOffset: "00:10.0"
            }
          }
        };
      }
    }
  };
}).call(this);
