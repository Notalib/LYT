(function() {
  var FileInterface;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  FileInterface = (function() {
    FileInterface.prototype.PLAYLIST = void 0;
    FileInterface.prototype.DODPUriTransLate = void 0;
    FileInterface.prototype.smilCacheTable = void 0;
    FileInterface.prototype.smilNamesToBeAdded = new Array();
    FileInterface.prototype.rememberSoundFile = new Array();
    FileInterface.prototype.htmlCacheTable = void 0;
    FileInterface.prototype.firstHtmlFilePart = "";
    FileInterface.prototype.sizeOfFirstHtmlFilePart = 65536;
    FileInterface.prototype.GotBookFired = false;
    FileInterface.prototype.audioTagList = new Array();
    FileInterface.prototype.textTagList = new Array();
    FileInterface.prototype.smilFilesInBuffer = 0;
    FileInterface.prototype.smilCacheSize = 10;
    FileInterface.prototype.smilFilesToCache = 3;
    FileInterface.prototype.smilCacheError = false;
    FileInterface.prototype.smilCacheTrigger = FileInterface.smilCacheSize - 3;
    FileInterface.prototype.currentSmilFile = "";
    FileInterface.prototype.currentAElement = void 0;
    FileInterface.prototype.nextAElement = void 0;
    FileInterface.prototype.nextSoundFileName = "";
    FileInterface.prototype.currentTimeInSmil = "";
    FileInterface.prototype.totalsec = 0;
    FileInterface.prototype.MaxBooksInlocalStorage = 20;
    FileInterface.prototype.GetAllTheText = void 0;
    FileInterface.prototype.clipBegin = void 0;
    FileInterface.prototype.clipEnd = void 0;
    FileInterface.prototype.GlobalCount = 0;
    FileInterface.prototype.soundfilename = "";
    FileInterface.prototype.tempTextList = void 0;
    FileInterface.prototype.DODP_DEFAULT_TIMEOUT = 30000;
    FileInterface.prototype.DODP_URL = "/DodpMobile/Service.svc";
    FileInterface.prototype.SERVICE_ANNOUNCEMENTS = false;
    FileInterface.prototype.SHOW_SERVICE_ANNOUNCEMENTS = false;
    FileInterface.prototype.soapTemplate = "<?xml version='1.0' encoding='UTF-8'?><SOAP-ENV:Envelope xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:ns1='http://www.daisy.org/ns/daisy-online/'><SOAP-ENV:Body>${soapBody}</SOAP-ENV:Body></SOAP-ENV:Envelope>";
    function FileInterface() {
      this.CreateListCallback = __bind(this.CreateListCallback, this);;
      this.GetContentResourcesCallBack = __bind(this.GetContentResourcesCallBack, this);;
      this.ReturnContentCallBack = __bind(this.ReturnContentCallBack, this);;
      this.IssueContentCallBack = __bind(this.IssueContentCallBack, this);;
      this.GetContentListCallBack = __bind(this.GetContentListCallBack, this);;
      this.GetServiceAnnouncementsCallBack = __bind(this.GetServiceAnnouncementsCallBack, this);;
      this.SetReadingSystemAttributesCallBack = __bind(this.SetReadingSystemAttributesCallBack, this);;
      this.GetServiceAttributesCallBack = __bind(this.GetServiceAttributesCallBack, this);;
      this.LogOnCallBack = __bind(this.LogOnCallBack, this);;
    }
    FileInterface.prototype.LogOnCallBack = function(response) {
      if (window.console) {
        console.log("PRO: Log on callback");
      }
      if ($(response).find("logOnResult").text() === "true") {
        return this.GetServiceAttributes();
      } else {
        return window.app.eventSystemForceLogin("Du har indtastet et forkert brugernavn eller password");
      }
    };
    FileInterface.prototype.OnError = function(jqXHR, textStatus, errorThrown) {
      if (window.console) {
        console.log("PRO: Error: ", jqXHR);
      }
      if (jqXHR.responseText === "undefined" || !(jqXHR.responseText != null)) {
        if (window.console) {
          console.log(errorThrown);
        }
        if (window.console) {
          console.log(jqXHR);
        }
        return;
      }
      if (jqXHR.responseText.indexOf("Session is invalid") > 0 || jqXHR.responseText.indexOf("Session is uninitialized") > 0) {
        return window.app.eventSystemNotLoggedIn();
      } else {
        if (window.console) {
          console.log(errorThrown + jqXHR.responseText);
        }
        if (window.console) {
          return console.log(jqXHR);
        }
      }
    };
    FileInterface.prototype.LogOffCallBack = function(response) {
      if (window.console) {
        console.log("PRO: LogOff...");
      }
      if ($(response).find("logOffResult") != null) {
        return window.app.eventSystemLoggedOff($(response).find("logOffResult").text());
      }
    };
    FileInterface.prototype.GetServiceAttributesCallBack = function(response) {
      var p;
      if (window.console) {
        console.log("PRO: Service attributtes callback");
      }
      p = $(response).find("supportedOptionalOperations");
      $(p).find("operation").each(function() {
        if ($(this).text() === "SERVICE_ANNOUNCEMENTS") {
          return this.SERVICE_ANNOUNCEMENTS = true;
        }
      });
      return this.SetReadingSystemAttributes();
    };
    FileInterface.prototype.SetReadingSystemAttributesCallBack = function(response) {
      if (window.console) {
        console.log("PRO: Set reading system attributes callback\t");
      }
      if ($(response).find("setReadingSystemAttributesResult").text() === "true") {
        if (this.SERVICE_ANNOUNCEMENTS && this.SHOW_SERVICE_ANNOUNCEMENTS) {
          this.GetServiceAnnouncements();
        }
        return window.app.eventSystemLoggedOn(true, $(response).find("MemberId").text());
      } else {
        return alert(aLang.Translate("MESSAGE_LOGON_FAILED"));
      }
    };
    FileInterface.prototype.GetServiceAnnouncementsCallBack = function(response) {
      var p;
      p = $(response).find("announcements");
      return $(p).find("announcement").each(function() {
        alert($(this).find("text").text());
        return this.MarkAnnouncementsAsRead($(this).attr("id"));
      });
    };
    FileInterface.prototype.GetContentListCallBack = function(response) {
      if ($(response).find("faultstring").text() === "Session is invalid" || $(response).find("faultstring").text() === "Session is uninitialized" || $(response).find("faultstring").text() === "Session has not been initialized") {
        if (window.console) {
          console.log("PRO: Boghylde callback\tfejl: ikke logget på, kalder eventSystemNotLoggedIn");
        }
        return window.app.eventSystemNotLoggedIn();
      } else {
        if (window.console) {
          console.log("PRO: Boghylde callback\t");
        }
        return window.app.eventSystemGotBookShelf(response);
      }
    };
    FileInterface.prototype.IssueContentCallBack = function(response) {
      if (window.console) {
        console.log("PRO: IssuecontentCallback ...");
      }
      if ($(response).find("faultstring").text() === "Session is invalid") {
        return window.app.eventSystemNotLoggedIn();
      } else {
        if ($(response).find("issueContentResult").text() === "true") {
          return this.GetContentResources(window.app.settings.currentBook);
        } else {
          return alert($(response).find("faultcode").text() + " - " + $(response).find("faultstring").text());
        }
      }
    };
    FileInterface.prototype.ReturnContentCallBack = function(response) {
      if (window.console) {
        console.log("PRO: ReturncontentCallback ...");
      }
      if ($(response).find("faultstring").text() === "Session is invalid") {
        return window.app.eventSystemNotLoggedIn();
      } else {
        if ($(response).find("returnContentResult").text() === "true") {
          return this.GetBookShelf();
        } else {
          return alert($(response).find("faultcode").text() + " - " + $(response).find("faultstring").text());
        }
      }
    };
    FileInterface.prototype.GetContentResourcesCallBack = function(response) {
      var doc, nccPath, parser;
      if (window.console) {
        console.log("PRO: Get content resources callback  - Bog ressourcer", response);
      }
      this.InitSystem();
      nccPath = "";
      if ($(response).find("faultstring").text() === "") {
        $(response).find("resource").each(function() {
          var aHost, aProtocol, dodpHost, temp;
          aHost = window.location.hostname;
          dodpHost = $(this).attr("uri");
          aProtocol = dodpHost.substring(0, dodpHost.indexOf("/") + 2);
          dodpHost = dodpHost.substring(dodpHost.indexOf("/") + 2);
          dodpHost = dodpHost.substring(dodpHost.indexOf("/"));
          this.DODPUriTranslate[$(this).attr("localURI")] = aProtocol + aHost + dodpHost;
          temp = $(this).attr("uri");
          if (temp.indexOf("ncc.htm") !== -1 && temp.substring(temp.length - 4, temp.length) !== ".bak") {
            return nccPath = aProtocol + aHost + dodpHost;
          }
        });
      } else {
        if ($(response).find("faultcode").text() === "s:invalidParameterFault") {
          alert($(response).find("faultstring").text());
          window.app.eventSystemEndLoading();
        } else {
          alert("Fejl i contentresourcescallback: " + $(response).find("faultstring").text());
        }
      }
      this.GotBookFired = false;
      if (!this.supports_local_storage()) {
        this.CreateList(nccPath);
      } else {
        try {
          window.app.book_tree = localStorage.getItem("NCC/" + window.app.settings.currentBook);
          if (!(window.app.book_tree != null) || window.app.book_tree === undefined || (window.app.book_tree.indexOf("ol") === -1)) {
            this.CreateList(nccPath);
            try {
              if (localStorage.length > this.MaxBooksInlocalStorage) {
                this.DeleteNccFromLocalStorage();
              }
              localStorage.setItem("NCC/" + window.app.settings.currentBook, window.app.book_tree);
            } catch (e) {
              if (e === QUOTA_EXCEEDED_ERR) {
                localStorage.clear();
              }
            }
          }
        } catch (e) {
          alert("Error on retrieve NCC");
        }
      }
      if (window.DOMParser) {
        try {
          parser = new DOMParser();
          doc = parser.parseFromString(book_tree, "text/xml");
        } catch (e) {
          alert(e.message);
        }
      } else {
        doc = new ActiveXObject("Microsoft.XMLDOM");
        doc.async = "false";
        doc.loadXML(book_tree);
      }
      this.PLAYLIST = doc.getElementsByTagName("li");
      this.PrePareSmilNames(this.PLAYLIST[0], this.smilCacheSize);
      return this.CacheSmilFiles();
    };
    FileInterface.prototype.LogOff = function() {
      var logOff_Soap;
      logOff_Soap = "<ns1:logOff></ns1:logOff>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/logOff"]
        },
        type: "POST",
        processData: true,
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", logOff_Soap),
        cache: false,
        success: this.LogOffCallBack,
        error: this.OnError,
        complete: this.LogOffcompleteCallBack
      });
    };
    FileInterface.prototype.LogOn = function(username, password) {
      var logOn_Soap;
      if (window.console) {
        console.log("PRO: Log on: " + username + " | " + password);
      }
      logOn_Soap = "<ns1:logOn><ns1:username>" + username + "</ns1:username><ns1:password>" + password + "</ns1:password></ns1:logOn>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/logOn"]
        },
        type: "POST",
        processData: true,
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", logOn_Soap),
        cache: false,
        success: this.LogOnCallBack,
        error: this.OnError,
        complete: this.LogOncompleteCallBack
      });
    };
    FileInterface.prototype.GetServiceAttributes = function() {
      var serviceAttributes_Soap;
      serviceAttributes_Soap = "<ns1:getServiceAttributes/>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/getServiceAttributes"]
        },
        type: "POST",
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", serviceAttributes_Soap),
        cache: false,
        success: this.GetServiceAttributesCallBack,
        error: this.OnError,
        complete: this.GetServiceAttributescompleteCallBack
      });
    };
    FileInterface.prototype.SetReadingSystemAttributes = function() {
      var readingSystemAttributes_Soap;
      readingSystemAttributes_Soap = "<ns1:setReadingSystemAttributes><ns1:readingSystemAttributes><ns1:manufacturer>NOTA</ns1:manufacturer><ns1:model>LYT</ns1:model><ns1:serialNumber>1</ns1:serialNumber><ns1:version>1</ns1:version><ns1:config></ns1:config></ns1:readingSystemAttributes></ns1:setReadingSystemAttributes>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/setReadingSystemAttributes"]
        },
        type: "POST",
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", readingSystemAttributes_Soap),
        cache: false,
        success: this.SetReadingSystemAttributesCallBack,
        error: this.OnError,
        complete: this.SetReadingSystemAttributescompleteCallBack
      });
    };
    FileInterface.prototype.GetServiceAnnouncements = function() {
      var getServiceAnnouncements_Soap;
      getServiceAnnouncements_Soap = "<ns1:getServiceAnnouncements/>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/getServiceAnnouncements"]
        },
        type: "POST",
        processData: true,
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", getServiceAnnouncements_Soap),
        cache: false,
        success: this.GetServiceAnnouncementsCallBack,
        error: this.OnError,
        complete: this.GetServiceAnnouncementscompleteCallBack
      });
    };
    FileInterface.prototype.MarkAnnouncementsAsRead = function(aId) {
      var MarkAnnouncementsAsRead_Soap;
      MarkAnnouncementsAsRead_Soap = "<ns1:markAnnouncementsAsRead><ns1:read><ns1:item>" + aId + "</ns1:item></ns1:read></ns1:markAnnouncementsAsRead>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/markAnnouncementsAsRead"]
        },
        type: "POST",
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", MarkAnnouncementsAsRead_Soap),
        cache: false,
        success: this.MarkAnnouncementsAsReadCallBack,
        error: this.OnError,
        complete: this.MarkAnnouncementsAsReadcompleteCallBack
      });
    };
    FileInterface.prototype.GetContentList = function(listName, firstItem, lastItem) {
      var GetContentList_Soap;
      if (window.console) {
        console.log("PRO: Henter boghylde...");
      }
      GetContentList_Soap = "<ns1:getContentList><ns1:id>" + listName + "</ns1:id><ns1:firstItem>" + firstItem + "</ns1:firstItem><ns1:lastItem>" + lastItem + "</ns1:lastItem></ns1:getContentList>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/getContentList"]
        },
        type: "POST",
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", GetContentList_Soap),
        cache: false,
        success: this.GetContentListCallBack,
        error: this.OnError,
        complete: this.GetContentListcompleteCallBack
      });
    };
    FileInterface.prototype.IssueContent = function(bookId) {
      var IssueContent_Soap;
      if (window.console) {
        console.log("PRO: Issue content: bookid: ", bookId);
      }
      IssueContent_Soap = "<ns1:issueContent><ns1:contentID>" + bookId + "</ns1:contentID></ns1:issueContent>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/issueContent"]
        },
        type: "POST",
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", IssueContent_Soap),
        cache: false,
        success: this.IssueContentCallBack,
        error: this.OnError,
        complete: this.IssueContentcompleteCallBack
      });
    };
    FileInterface.prototype.ReturnContent = function(bookId) {
      var ReturnContent_Soap;
      if (window.console) {
        console.log("PRO: return content: bookid: ", bookId);
      }
      ReturnContent_Soap = "<ns1:returnContent><ns1:contentID>" + bookId + "</ns1:contentID></ns1:returnContent>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/returnContent"]
        },
        type: "POST",
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", ReturnContent_Soap),
        cache: false,
        success: this.ReturnContentCallBack,
        error: this.OnError,
        complete: this.ReturnContentcompleteCallBack
      });
    };
    FileInterface.prototype.GetContentMetadata = function(aId) {
      var ContentMetadata_Soap;
      ContentMetadata_Soap = "<ns1:getContentMetadata><ns1:contentID>" + aId + "</ns1:contentID></ns1:getContentMetadata>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/getContentMetadata"]
        },
        type: "POST",
        processData: true,
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", ContentMetadata_Soap),
        cache: false,
        success: this.GetContentMetadataCallBack,
        error: this.OnError,
        complete: this.GetContentMetadatacompleteCallBack
      });
    };
    FileInterface.prototype.GetContentResources = function(aId) {
      var ContentResources_Soap;
      if (window.console) {
        console.log("PRO: Kalder get content ressources...");
      }
      ContentResources_Soap = "<ns1:getContentResources><ns1:contentID>" + aId + "</ns1:contentID></ns1:getContentResources>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/getContentResources"]
        },
        type: "POST",
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", ContentResources_Soap),
        cache: false,
        success: this.GetContentResourcesCallBack,
        error: this.OnError,
        complete: this.GetContentResourcescompleteCallBack
      });
    };
    FileInterface.prototype.SetBookmarks = function(aId, BookMarksXml) {
      var bookmarks_Soap;
      bookmarks_Soap = "<ns1:setBookmarks><ns1:contentID>" + aId + "</ns1:contentID>" + BookMarksXml + "</ns1:setBookmarks>";
      return $.ajax({
        url: this.DODP_URL,
        headers: {
          SOAPAction: ["/setBookmarks"]
        },
        type: "POST",
        processData: true,
        contentType: "text/xml; charset=utf-8",
        timeout: this.DODP_DEFAULT_TIMEOUT,
        dataType: "xml",
        data: this.soapTemplate.replace("${soapBody}", bookmarks_Soap),
        cache: false,
        success: this.SetBookmarksCallBack,
        error: this.OnError,
        complete: this.SetBookmarkscompleteCallBack
      });
    };
    FileInterface.prototype.GetBookmarksSync = function(aId) {
      var URI, bookmarkXml, last, ncxref, t, text, timeOffset, uid;
      bookmarkXml = $("<bookmarkSet>");
      t = $("<title>");
      bookmarkXml.append(t);
      text = $("<text>");
      text.append(aId);
      t.append(text);
      t.append($("<audio>"));
      uid = $("<uid>");
      uid.append(aId);
      bookmarkXml.append(uid);
      last = $("<lastmark>");
      bookmarkXml.append(last);
      ncxref = $("<ncxRef>");
      ncxref.append("xyub00066");
      last.append(ncxref);
      URI = $("<URI>");
      URI.append("cddw000A.smil#xyub00066");
      last.append(URI);
      timeOffset = $("<timeOffset>");
      timeOffset.append("00:10.0");
      last.append(timeOffset);
      return bookmarkXml;
    };
    FileInterface.prototype.GetBookShelf = function() {
      return this.GetContentList("issued", "0", "-1");
    };
    FileInterface.prototype.GetBook = function(bookId) {
      if (window.console) {
        console.log("PRO: PRO: Getbook: bookid: ", bookId);
      }
      return this.IssueContent(bookId);
    };
    FileInterface.prototype.GetBookmarks = function(aId) {
      return this.GetBookmarksSync(aId);
    };
    FileInterface.prototype.CreateList = function(urlToBookNcc) {
      console.log("PRO: Creating list from: " + urlToBookNcc);
      return $.ajax({
        url: urlToBookNcc,
        type: "GET",
        dataType: "xml",
        async: false,
        success: this.CreateListCallback,
        error: this.OnError
      });
    };
    FileInterface.prototype.CreateListCallback = function(xml) {
      var currentlevel, difference, forfatter, formerlevel, me, savedforlater, string, title, totalTime;
      console.log("PRO: Create list callback", xml);
      string = "";
      currentlevel = 1;
      formerlevel = 1;
      difference = 0;
      savedforlater = void 0;
      me = "";
      forfatter = void 0;
      try {
        totalTime = xml.getElementsByName("ncc:totalTime")[0].getAttribute("content");
      } catch (_e) {}
      if (xml.getElementsByName("dc:creator").length !== 0) {
        forfatter = xml.getElementsByName("dc:creator")[0].getAttribute("content");
      } else {
        forfatter = "NN";
        title = xml.getElementsByName("dc:title")[0].getAttribute("content");
      }
      $(xml).find(":header").each(function(i) {
        var book_tree, _results;
        currentlevel = this.nodeName.toLowerCase().substr(1, 2);
        me = "<li id=\"" + $(this).attr("id") + "\" xhref=\"" + $(this).find("a").attr("href") + "\">" + $(this).find("a").text() + "</li>";
        if (formerlevel - currentlevel < 0) {
          string = string.slice(0, string.length - 5);
          string += "<ol>" + me;
        }
        if (formerlevel - currentlevel > 0) {
          i = 0;
          while (i < formerlevel - currentlevel) {
            string += "</ol></li>";
            i++;
          }
          string += me;
        }
        if (formerlevel - currentlevel === 0) {
          string += me;
        }
        formerlevel = this.nodeName.toLowerCase().substr(1, 2);
        if (currentlevel > 1) {
          i = 1;
          _results = [];
          while (i < currentlevel) {
            string += "</ol></li>";
            _results.push(i++);
          }
          return _results;
        } else {
          string += "</li>";
          string = "<ul titel=\"" + title + "\" forfatter=\"" + forfatter + "\" totalTime=\"" + totalTime + "\" id=\"NccRootElement\" data-role=\"listview\">" + string + "</ol>";
          return book_tree = string;
        }
      });
      if (window.console) {
        return console.log("PRO: NCC liste oversat til li...");
      }
    };
    FileInterface.prototype.PrePareSmilNames = function(node, count) {
      var i, j, temp, _results;
      if (window.console) {
        console.log("PRO: Prepare smile names");
      }
      j = this.findNode(node, this.PLAYLIST);
      if (j !== -1) {
        i = j;
        _results = [];
        while (i < this.PLAYLIST.length) {
          if ((i - j) < count) {
            temp = this.PLAYLIST[i].getAttribute("xhref").substring(this.PLAYLIST[i].getAttribute("xhref").lastIndexOf("/") + 1, this.PLAYLIST[i].getAttribute("xhref").indexOf("#"));
            this.smilNamestoBeAdded.push(temp);
          }
          _results.push(i++);
        }
        return _results;
      }
    };
    FileInterface.prototype.DeleteNccFromLocalStorage = function() {
      var j, _results;
      try {
        j = 0;
        _results = [];
        while (j < localStorage.length) {
          if (localStorage.key(j).indexOf("NCC/") !== -1) {
            localStorage.removeItem(localStorage.key(j));
            break;
          }
          _results.push(j++);
        }
        return _results;
      } catch (e) {
        return alert(e.message);
      }
    };
    FileInterface.prototype.CacheSmilFiles = function() {
      var xmlHttp1;
      if (window.console) {
        console.log("PRO: Caching smile files");
      }
      try {
        xmlHttp1 = new XMLHttpRequest();
      } catch (e) {
        try {
          xmlHttp1 = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
          try {
            xmlHttp1 = new ActiveXObject("Microsoft.XMLHTTP");
          } catch (e) {
            alert("Your browser does not support AJAX!");
            return false;
          }
        }
      }
      xmlHttp1.onreadystatechange = function() {
        var i;
        if (xmlHttp1.readyState === 4) {
          if (this.smilNamestoBeAdded.length > 0) {
            if (this.smilFilesInBuffer >= this.smilCacheSize) {
              i = 0;
              while (i < this.smilNamestoBeAdded.length) {
                delete this.smilCacheTable[this.smilCacheTableGetKey(i)];
                this.smilFilesInBuffer--;
                i++;
              }
            }
            this.currentSmilFile = this.smilNamestoBeAdded.shift();
            try {
              this.smilCacheTable[this.currentSmilFile] = xmlHttp1.responseXML;
              if (xmlHttp1.status !== 200) {
                this.smilCacheTable[this.currentSmilFile] = -1;
              }
              this.smilFilesInBuffer++;
              if (this.smilFilesInBuffer === 1) {
                this.GetHtmlName(this.smilCacheTable[this.currentSmilFile]);
              }
              return this.CacheSmilFiles();
            } catch (e) {
              return this.smilCacheError = true;
            }
          }
        }
      };
      if (this.smilNamestoBeAdded.length > 0) {
        if (xmlHttp1.overrideMimeType) {
          xmlHttp1.overrideMimeType("text/xml");
        }
        xmlHttp1.open("GET", this.DODPUriTranslate[this.smilNamestoBeAdded[0]], true);
        return xmlHttp1.send(null);
      }
    };
    FileInterface.prototype.CacheSmilFilesSync = function() {
      var i, xmlHttp3;
      try {
        xmlHttp3 = new XMLHttpRequest();
      } catch (e) {
        try {
          xmlHttp3 = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
          try {
            xmlHttp3 = new ActiveXObject("Microsoft.XMLHTTP");
          } catch (e) {
            alert("Your browser does not support AJAX!");
            return false;
          }
        }
      }
      if (this.smilNamestoBeAdded.length > 0) {
        if (xmlHttp3.overrideMimeType) {
          xmlHttp3.overrideMimeType("text/xml");
        }
        xmlHttp3.open("GET", this.DODPUriTranslate[this.smilNamestoBeAdded[0]], false);
        xmlHttp3.send(null);
        if (this.smilFilesInBuffer >= this.smilCacheSize) {
          i = 0;
          while (i < this.smilNamestoBeAdded.length) {
            delete this.smilCacheTable[this.smilCacheTableGetKey(i)];
            this.smilFilesInBuffer--;
            i++;
          }
        }
        this.currentSmilFile = this.smilNamestoBeAdded.shift();
        try {
          this.smilCacheTable[this.currentSmilFile] = xmlHttp3.responseXML;
          if (xmlHttp3.status !== 200) {
            this.smilCacheTable[this.currentSmilFile] = -1;
          }
          this.smilFilesInBuffer++;
          if (this.smilFilesInBuffer === 1) {
            return this.GetHtmlName(this.smilCacheTable[this.currentSmilFile]);
          }
        } catch (e) {
          return this.smilCacheError = true;
        }
      }
    };
    FileInterface.prototype.smilCacheTableGetKey = function(aIndex) {
      var i, n, _results;
      i = 0;
      _results = [];
      for (n in this.smilCacheTable) {
        if (i === aIndex) {
          return n;
        }
        _results.push(i++);
      }
      return _results;
    };
    FileInterface.prototype.smilCacheTableGetIndex = function(aKey) {
      var i, n, _results;
      i = 0;
      _results = [];
      for (n in this.smilCacheTable) {
        if (n === aKey) {
          return i;
        }
        _results.push(i++);
      }
      return _results;
    };
    FileInterface.prototype.findNode = function(node, list) {
      var i, returnV;
      returnV = -1;
      try {
        i = 0;
        while (i < list.length) {
          if (node.getAttribute("xhref") === list[i].getAttribute("xhref")) {
            returnV = i;
          }
          i++;
        }
      } catch (_e) {}
      return returnV;
    };
    FileInterface.prototype.CacheHtmlFile = function(htmlfileName, localname) {
      var xmlDoc1, xmlHttp;
      xmlHttp = void 0;
      try {
        xmlHttp = new XMLHttpRequest();
      } catch (e) {
        try {
          xmlHttp = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
          try {
            xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
          } catch (e) {
            alert("Your browser does not support AJAX!");
            return false;
          }
        }
      }
      xmlHttp.onreadystatechange = function() {
        if (xmlHttp.readyState === 3) {
          if (this.firstHtmlFilePart.length <= this.sizeOfFirstHtmlFilePart) {
            this.firstHtmlFilePart = xmlHttp.responseText;
          } else if (!this.GotBookFired) {
            window.app.eventSystemGotBook(book_tree);
            this.GotBookFired = true;
          }
        }
        if (xmlHttp.readyState === 4) {
          this.htmlCacheTable[localname] = xmlHttp.responseXML;
          this.ReplaceLocalURIInHtml(this.htmlCacheTable[localname]);
          if (!this.GotBookFired) {
            window.app.eventSystemGotBook(book_tree);
            return this.GotBookFired = true;
          }
        }
      };
      if (xmlHttp.overrideMimeType) {
        xmlHttp.overrideMimeType("text/xml");
        xmlHttp.open("GET", htmlfileName, true);
        return xmlHttp.send(null);
      } else {
        xmlDoc1 = void 0;
        xmlDoc1 = new ActiveXObject("Microsoft.XMLDOM");
        xmlDoc1.async = "false";
        try {
          xmlDoc1.load(htmlfileName);
          this.htmlCacheTable[localname] = xmlDoc1;
          return this.ReplaceLocalURIInHtml(this.htmlCacheTable[localname]);
        } catch (e) {
          return alert(e.message);
        }
      }
    };
    FileInterface.prototype.GetHtmlName = function(smilfileXml) {
      var htmlFileName;
      if (window.console) {
        console.log("PRO: GetHtmlName");
      }
      if (smilfileXml.getElementsByTagName("text").length !== 0) {
        htmlFileName = smilfileXml.getElementsByTagName("text")[0].getAttribute("src");
        htmlFileName = htmlFileName.substring(0, htmlFileName.indexOf("#"));
        return this.CacheHtmlFile(this.DODPUriTranslate[htmlFileName], htmlFileName);
      } else {
        return alert("ingen text");
      }
    };
    FileInterface.prototype.ReplaceLocalURIInHtml = function(html) {
      return $(html).find("img").each(function() {
        return $(this).attr("src", this.DODPUriTranslate[$(this).attr("src")]);
      });
    };
    FileInterface.prototype.supports_local_storage = function() {
      try {
        if (window["localStorage"] != null) {
          return true;
        }
      } catch (e) {
        return false;
      }
    };
    FileInterface.prototype.GetTextAndSound = function(aElement) {
      var i, p, pos, smilfile, smilid;
      if (Player.isSystemEvent) {
        Player.isSystemEvent = false;
      } else {
        Player.isUserEvent = true;
      }
      try {
        this.currentAElement = aElement;
        this.nextAElement = this.GetNextAElement(aElement);
        smilfile = aElement.getAttribute("xhref").substring(aElement.getAttribute("xhref").lastIndexOf("/") + 1, aElement.getAttribute("xhref").indexOf("#"));
        this.currentSmilFile = smilfile;
        smilid = aElement.getAttribute("xhref").substr(aElement.getAttribute("xhref").indexOf("#") + 1);
        if (this.smilCacheTable[smilfile] === undefined) {
          p = this.findNode(aElement, this.PLAYLIST);
          this.PrePareSmilNames(this.PLAYLIST[p], 1);
          this.CacheSmilFilesSync();
          return this.GetTextAndSound(aElement);
        } else if (this.smilCacheError) {
          return alert("There is a problem with the cache");
        } else {
          window.globals.text_window.innerHTML = "";
          pos = this.smilCacheTableGetIndex(smilfile);
          if (pos > this.smilCacheTrigger) {
            p = this.findNode(aElement, this.PLAYLIST) + (this.smilCacheSize - pos);
            this.PrePareSmilNames(this.PLAYLIST[p], this.smilFilesToCache);
            this.CacheSmilFiles();
          }
          this.soundfilename = this.smilCacheTable[smilfile].getElementsByTagName("audio")[0].getAttribute("src");
          this.nextSoundFileName = this.GetNextSoundFileName(this.smilCacheTable[smilfile], smilfile);
          this.tempTextList = this.smilCacheTable[smilfile].getElementsByTagName("text");
          this.textTagList.length = 0;
          i = 0;
          while (i < this.tempTextList.length) {
            this.textTagList[i] = this.tempTextList[i];
            i++;
          }
          if (window.app.settings.textMode === 2) {
            this.GetAllTheText = true;
          }
          if (!Player.LastPartNCCJump) {
            this.currentTimeInSmil = this.smilCacheTable[smilfile].getElementsByName("ncc:totalElapsedTime")[0].getAttribute("content");
            this.SetTotalSeconds(this.currentTimeInSmil);
            this.GetTextAndSoundPiece(smilid, this.smilCacheTable[smilfile]);
            return this.textTagList.shift();
          } else {
            return Player.LastPartNCCJump = false;
          }
        }
      } catch (e) {
        return false;
      }
    };
    FileInterface.prototype.GetNextAElement = function(aElement) {
      var i;
      try {
        i = 0;
        while (i < this.PLAYLIST.length) {
          if (this.PLAYLIST[i].getAttribute("xhref") === aElement.getAttribute("xhref")) {
            return this.PLAYLIST.item(i + 1);
          }
          i++;
        }
        return null;
      } catch (e) {
        return null;
      }
    };
    FileInterface.prototype.GetLastAElement = function(aElement) {
      var i;
      try {
        i = 0;
        while (i < this.PLAYLIST.length) {
          if (this.PLAYLIST[i].getAttribute("xhref") === aElement.getAttribute("xhref")) {
            return this.PLAYLIST.item(i - 1);
          }
          i++;
        }
        return null;
      } catch (e) {
        return null;
      }
    };
    FileInterface.prototype.GetNextSoundFileName = function(smilCacheEntry, smilname) {
      var aIndex, found, i, temp, tempList;
      found = false;
      try {
        tempList = smilCacheEntry.getElementsByTagName("audio");
        if (tempList.length !== 0) {
          i = 0;
          while (i < tempList.length) {
            if (tempList[i].getAttribute("src") !== this.soundfilename) {
              this.soundfilename = tempList[i].getAttribute("src");
              found = true;
              break;
            }
            i++;
          }
          if (!found) {
            aIndex = void 0;
            aIndex = this.smilCacheTableGetIndex(smilname);
            if (aIndex < this.smilCacheSize) {
              temp = this.smilCacheTableGetKey(aIndex + 1);
              if (this.smilCacheTable[temp] !== undefined) {
                this.GetNextSoundFileName(this.smilCacheTable[temp], temp);
              } else {
                this.soundfilename = "";
              }
            }
          }
        }
      } catch (e) {
        alert(e.message);
      }
      return this.soundfilename;
    };
    FileInterface.prototype.GetTextAndSoundPiece = function(aSmilId, smilfileXml) {
      var audio, i, id, temp, tempList, _results;
      try {
        switch (smilfileXml.nodeType) {
          case 1:
            switch (smilfileXml.nodeName.toUpperCase()) {
              case "TEXT":
                id = $(smilfileXml).attr("id");
                if (window.app.settings.textMode === 1) {
                  if (id === aSmilId) {
                    temp = smilfileXml.getAttribute("src");
                    GetText(temp.substring(0, temp.indexOf("#")), temp.substr(temp.indexOf("#") + 1));
                    tempList = smilfileXml.parentNode.getElementsByTagName("audio");
                    i = 0;
                    while (i < tempList.length) {
                      this.audioTagList[i] = tempList[i];
                      i++;
                    }
                    audio = this.audioTagList.shift();
                    this.GetSound(this.DODPUriTranslate[audio.getAttribute("src")], audio.getAttribute("clip-begin"), audio.getAttribute("clip-end"));
                  }
                } else {
                  if (this.GetAllTheText) {
                    temp = smilfileXml.getAttribute("src");
                    GetText(temp.substring(0, temp.indexOf("#")), temp.substr(temp.indexOf("#") + 1));
                  }
                  if (id === aSmilId) {
                    tempList = smilfileXml.parentNode.getElementsByTagName("audio");
                    i = 0;
                    while (i < tempList.length) {
                      this.audioTagList[i] = tempList[i];
                      i++;
                    }
                    audio = this.audioTagList.shift();
                    this.GetSound(this.DODPUriTranslate[audio.getAttribute("src")], audio.getAttribute("clip-begin"), audio.getAttribute("clip-end"));
                  }
                }
                break;
            }
            break;
        }
        i = 0;
        _results = [];
        while (i < smilfileXml.childNodes.length) {
          this.GetTextAndSoundPiece(aSmilId, smilfileXml.childNodes[i]);
          _results.push(i++);
        }
        return _results;
      } catch (e) {
        return alert(e.message);
      }
    };
    FileInterface.prototype.FindEndTag = function(html, startPoint) {
      try {
        html = html.substr(startPoint);
        this.GlobalCount += html.indexOf("<");
        if (html.substring(html.indexOf("<") + 1, html.indexOf("<") + 2) === "/") {
          return this.FindEndTag(html, html.indexOf("<") + 1);
        }
      } catch (e) {
        return alert(e.message);
      }
    };
    FileInterface.prototype.updateTime = function(currentTime) {
      try {
        return window.app.eventSystemTime(currentTime + this.totalsec);
      } catch (e) {
        return alert(e.message);
      }
    };
    FileInterface.prototype.SetTotalSeconds = function(total) {
      this.totalsec = parseInt(total.substr(0, 2), 10) * 60 * 60;
      this.totalsec = this.totalsec + (parseInt(total.substr(3, 2), 10) * 60);
      return this.totalsec = this.totalsec + parseInt(total.substr(6, 2), 10);
    };
    FileInterface.prototype.SecToTime = function(aTime) {
      var houers, min, sec, temp;
      temp = void 0;
      houers = void 0;
      min = void 0;
      sec = void 0;
      houers = (aTime / 60) / 60;
      houers = houers.toString();
      min = houers.substring(houers.indexOf("."), (houers.length - 1) - houers.indexOf("."));
      min = "0" + min;
      min = min * 60;
      min = min.toString();
      sec = min.substring(min.indexOf("."), (min.length - 1) - min.indexOf("."));
      sec = "0" + sec;
      sec = sec * 60;
      sec = sec.toString();
      houers = houers.substring(0, houers.indexOf("."));
      min = min.substring(0, min.indexOf("."));
      sec = sec.substring(0, sec.indexOf("."));
      if (houers.length < 2) {
        houers = "0" + houers;
      }
      if (min.length < 2) {
        min = "0" + min;
      }
      if (sec.length < 2) {
        sec = "0" + sec;
      }
      temp = houers + ":" + min + ":" + sec;
      return temp;
    };
    FileInterface.prototype.GetText = function(htmlfileName, aId) {
      var html, htmlPart, node, parameter, part, startTemp, stopTemp, t, temp, temp1, temp2;
      try {
        if (this.htmlCacheTable[htmlfileName] !== undefined || (this.htmlCacheTable[htmlfileName] != null)) {
          html = this.htmlCacheTable[htmlfileName];
          parameter = "//*[@id='" + aId + "']";
          if (document.evaluate) {
            part = html.evaluate(parameter, html, null, XPathResult.ANY_TYPE, null);
            node = part.iterateNext();
            return window.app.eventSystemTextChanged("", node, "", this.currentAElement.firstChild.nodeValue);
          } else {
            temp = null;
            t = $(this.htmlCacheTable[htmlfileName]);
            t.find("*").each(function() {
              if ($(this).attr("id") === aId) {
                return temp = document.createTextNode($(this).text());
              }
            });
            return window.app.eventSystemTextChanged("", temp, "", this.currentAElement.firstChild.nodeValue);
          }
        } else {
          if (this.firstHtmlFilePart.indexOf(aId) !== -1) {
            temp1 = this.firstHtmlFilePart.substring(0, this.firstHtmlFilePart.indexOf(aId));
            startTemp = temp1.lastIndexOf("<");
            temp2 = this.firstHtmlFilePart.substr(this.firstHtmlFilePart.indexOf(aId));
            stopTemp = temp2.indexOf("</");
            this.GlobalCount = 0;
            this.FindEndTag(temp2, stopTemp);
            htmlPart = this.firstHtmlFilePart.substring(startTemp, temp1.length + stopTemp + this.GlobalCount);
            temp = document.createTextNode($(htmlPart).text());
            return window.app.eventSystemTextChanged("", temp, "", this.currentAElement.firstChild.nodeValue);
          }
        }
      } catch (e) {
        return alert(e.message);
      }
    };
    FileInterface.prototype.GetSound = function(UrlToSound, aStart, aEnd) {
      if (Player.player.canPlayType("audio/mpeg") === "") {
        alert("kan ikke afspille mp3 format");
        return;
      }
      if (Player.userPaused) {
        this.rememberSoundFile[0] = UrlToSound;
        this.rememberSoundFile[1] = aStart;
        this.rememberSoundFile[2] = aEnd;
        return;
      }
      try {
        clearInterval(Player.BeginPolling);
        if (Player.player.src.indexOf(UrlToSound) === -1) {
          if (Player.isCached(UrlToSound)) {
            Player.SwitchPlayer();
          } else {
            console.log("PRO: Requesting next sound file " + UrlToSound);
            this.LogOn(window.app.settings.username, window.app.settings.password);
            Player.player.src = UrlToSound;
            Player.player.preload = "metadata";
            Player.player.load();
          }
          if (this.nextSoundFileName !== "") {
            console.log("PRO: caching next sondfile" + this.nextSoundFileName);
            this.LogOn(window.app.settings.username, window.app.settings.password);
            Player.CacheNextSoundFile(this.DODPUriTranslate[this.nextSoundFileName]);
          }
        }
        this.clipBegin = aStart.slice(4, -1);
        this.clipBegin = parseFloat(this.clipBegin);
        if (Player.player.readyState !== 0) {
          try {
            if (this.clipBegin !== Player.stopTime || Player.player.currentTime < Player.stopTime) {
              Player.player.pause();
              Player.player.currentTime = this.clipBegin;
              if (this.clipBegin === 0) {
                setTimeout("Player.player.play()", 500);
              }
            } else {
              if (Player.player.paused) {
                Player.player.play();
              }
            }
          } catch (_e) {}
        }
        this.clipEnd = aEnd.slice(4, -1);
        this.clipEnd = parseFloat(this.clipEnd);
        Player.startTime = this.clipBegin;
        Player.stopTime = this.clipEnd;
        return Player.BeginPolling = setInterval("Player.CheckEndTime()", 50);
      } catch (e) {
        return alert(e.message);
      }
    };
    FileInterface.prototype.eventSystemPaused = function() {
      var aTextTag, audio;
      try {
        if (this.audioTagList.length > 0) {
          audio = this.audioTagList.shift();
          return this.GetSound(this.DODPUriTranslate[audio.getAttribute("src")], audio.getAttribute("clip-begin"), audio.getAttribute("clip-end"));
        } else if (this.textTagList.length > 0) {
          aTextTag = this.textTagList.shift();
          this.GetAllTheText = false;
          return this.GetTextAndSoundPiece(aTextTag.getAttribute("id"), this.smilCacheTable[this.currentSmilFile]);
        } else if (this.nextAElement != null) {
          Player.isSystemEvent = true;
          return this.GetTextAndSound(this.nextAElement);
        }
      } catch (e) {
        return alert(e.message);
      }
    };
    FileInterface.prototype.InitSystem = function() {
      this.DODPUriTranslate = new Object();
      this.smilCacheTable = new Object();
      this.smilNamestoBeAdded = new Array();
      this.rememberSoundFile = new Array();
      this.smilFilesInBuffer = 0;
      this.htmlCacheTable = new Object();
      this.firstHtmlFilePart = "";
      this.GotBookFired = false;
      this.audioTagList = new Array();
      this.textTagList = new Array();
      this.smilCacheError = false;
      this.currentSmilFile = "";
      this.currentAElement = null;
      this.nextAElement = null;
      this.nextSoundFileName = "";
      this.currentTimeInSmil = "";
      return this.totalsec = 0;
      /*
      This shouldn't be in the fileinterface class, but defaults in the player.
      Pause()
      Player.player.startTime = 0
      Player.player.stopTime = 0
      Player.player.BeginPolling = 0
      Player.player.LastPartNCCJump = false
      Player.player.userPaused = false
      */
    };
    return FileInterface;
  })();
  window.FileInterface = FileInterface;
}).call(this);
