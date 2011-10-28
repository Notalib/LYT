(function() {
  this.protocol = {
    logOn: {
      request: function(username, password) {
        return {
          username: username,
          password: password
        };
      },
      receive: function($xml, data) {
        if ($xml.find("logOnResult").text() === "true") {
          return rpc("getServiceAttributes");
        } else {
          return eventSystemForceLogin("Du har indtastet et forkert brugernavn eller password");
        }
      }
    },
    logOff: {
      receive: function($xml, data) {
        var _ref;
        return eventSystemLogedOff(((_ref = $xml.find("logOffResult")) != null ? _ref.text() : void 0) || "");
      }
    },
    getServiceAttributes: {
      receive: function($xml, data) {
        $xml.find("supportedOptionalOperations > operation").each(function() {
          var op;
          op = jQuery(this);
          return DODP.service.announcements = op.text() === "SERVICE_ANNOUNCEMENTS";
        });
        return rpc("setReadingSystemAttributes");
      }
    },
    setReadingSystemAttributes: {
      request: function() {
        return {
          readingSystemAttributes: {
            manufacturer: "NOTA",
            model: "LYT",
            serialNumber: "1",
            version: "1",
            config: null
          }
        };
      },
      receive: function($xml, data) {
        if ($xml.find("setReadingSystemAttributesResult").text() === "true") {
          eventSystemLogedOn(true, $xml.find("MemberId").text());
          if (DODP.service.announcements && false) {
            return rpc("getServiceAnnouncements");
          }
        } else {
          return alert(aLang.translate("MESSAGE_LOGON_FAILED"));
        }
      }
    },
    getServiceAnnouncements: {
      receive: function($xml, data) {
        return $xml.find("announcements > announcement").each(function() {
          var announcement;
          announcement = jQuery(this);
          alert(announcement.find("text").text());
          return rpc("markAnnouncementsAsRead", announcement.id);
        });
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
        return eventSystemGotBookShelf(data);
      }
    },
    issueContent: {
      request: function(bookID) {
        return {
          contentID: bookID
        };
      },
      receive: function($xml) {
        if ($xml.find('issueContentResult').text() === "true") {
          return rpc("getContentResources", settings.currentBook);
        } else {
          log.error("PRO: Error in issueContent parsing: " + ($xml.find("faultcode").text()) + " - " + ($xml.find('faultstring').text()));
          return alert("" + ($xml.find("faultcode").text()) + " - " + ($xml.find('faultstring').text()));
        }
      }
    },
    returnContent: {
      request: function(bookID) {
        return {
          contentId: bookID
        };
      },
      receive: function($xml) {
        if ($xml.find("returnContentResult").text() === "true") {
          return rpc("getBookShelf");
        } else {
          log.error("PRO: Error in returnContent parsing: " + ($xml.find("faultcode").text()) + " - " + ($xml.find('faultstring').text()));
          return alert("" + ($xml.find("faultcode").text()) + " - " + ($xml.find('faultstring').text()));
        }
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
        var fault;
        fault = $xml.find('faultstring').text();
        if (fault !== "") {
          if (fault === "s:invalidParameterFault") {
            eventSystemEndLoading();
          }
          log.error("PRO: Resource error: " + fault);
          return;
        }
        return $xml.find("resource").each(function() {
          var components, nccPath, resource, resourceURI, url;
          resource = jQuery(this);
          resourceURI = resource.attr("uri");
          components = resourceURI.match(/^([^\/]+)\/\/([^\/]+)\/(.*)$/);
          url = "" + components[1] + "//" + window.location.hostame + "/" + components[3];
          if (resourceURI.match(/ncc.htm$/i)) {
            return nccPath = url;
          }
        });
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
