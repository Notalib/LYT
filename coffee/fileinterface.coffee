class FileInterface
    
    PLAYLIST: undefined
    DODPUriTransLate: undefined
    smilCacheTable: undefined
    smilNamesToBeAdded: new Array()
    rememberSoundFile: new Array()
    htmlCacheTable: undefined
    firstHtmlFilePart: ""
    sizeOfFirstHtmlFilePart: 65536
    GotBookFired: false
    audioTagList: new Array()
    textTagList: new Array()
    smilFilesInBuffer: 0
    smilCacheSize: 10
    smilFilesToCache: 3
    smilCacheError: false
    smilCacheTrigger: @smilCacheSize - 3
    currentSmilFile: ""
    currentAElement: undefined
    nextAElement: undefined
    nextSoundFileName: ""
    currentTimeInSmil: ""
    totalsec: 0
    MaxBooksInlocalStorage: 20
    GetAllTheText: undefined
    clipBegin: undefined
    clipEnd: undefined
    GlobalCount: 0
    soundfilename: ""
    tempTextList: undefined
    DODP_DEFAULT_TIMEOUT: 30000
    DODP_URL: "/DodpMobile/Service.svc"
    SERVICE_ANNOUNCEMENTS: false
    SHOW_SERVICE_ANNOUNCEMENTS: false
    soapTemplate: "<?xml version='1.0' encoding='UTF-8'?><SOAP-ENV:Envelope xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:ns1='http://www.daisy.org/ns/daisy-online/'><SOAP-ENV:Body>${soapBody}</SOAP-ENV:Body></SOAP-ENV:Envelope>"
    
    constructor: () ->
    
    LogOnCallBack: (response) =>
        console.log "PRO: Log on callback"  if window.console
        if $(response).find("logOnResult").text() is "true"
            @GetServiceAttributes()
        else
            window.app.eventSystemForceLogin "Du har indtastet et forkert brugernavn eller password"    
    
    OnError: (jqXHR, textStatus, errorThrown) ->
        console.log "PRO: Error: ", jqXHR  if window.console
        if jqXHR.responseText is "undefined" or not jqXHR.responseText?
            console.log errorThrown  if window.console
            console.log jqXHR  if window.console
            return
        if jqXHR.responseText.indexOf("Session is invalid") > 0 or jqXHR.responseText.indexOf("Session is uninitialized") > 0
            window.app.eventSystemNotLoggedIn()
        else
            console.log errorThrown + jqXHR.responseText  if window.console
            console.log jqXHR  if window.console

    LogOffCallBack: (response) ->
        console.log "PRO: LogOff..."  if window.console
        window.app.eventSystemLoggedOff $(response).find("logOffResult").text()  if $(response).find("logOffResult")?
	
    GetServiceAttributesCallBack: (response) =>
        console.log "PRO: Service attributtes callback"  if window.console
        p = $(response).find("supportedOptionalOperations")
        $(p).find("operation").each ->
            @SERVICE_ANNOUNCEMENTS = true  if $(this).text() is "SERVICE_ANNOUNCEMENTS"
        @SetReadingSystemAttributes()

    SetReadingSystemAttributesCallBack: (response) =>
        console.log "PRO: Set reading system attributes callback\t"  if window.console
        if $(response).find("setReadingSystemAttributesResult").text() is "true"
            @GetServiceAnnouncements()  if @SERVICE_ANNOUNCEMENTS and @SHOW_SERVICE_ANNOUNCEMENTS
            window.app.eventSystemLoggedOn true, $(response).find("MemberId").text()
        else
            alert aLang.Translate("MESSAGE_LOGON_FAILED")

    GetServiceAnnouncementsCallBack: (response) =>
        p = $(response).find("announcements")
        $(p).find("announcement").each ->
            alert $(this).find("text").text()
            @MarkAnnouncementsAsRead $(this).attr("id")

    GetContentListCallBack: (response) =>
        if $(response).find("faultstring").text() is "Session is invalid" or $(response).find("faultstring").text() is "Session is uninitialized" or $(response).find("faultstring").text() is "Session has not been initialized"
            console.log "PRO: Boghylde callback\tfejl: ikke logget på, kalder eventSystemNotLoggedIn"  if window.console
            window.app.eventSystemNotLoggedIn()
        else
            console.log "PRO: Boghylde callback\t"  if window.console
            window.app.eventSystemGotBookShelf response

    IssueContentCallBack: (response) =>
        console.log "PRO: IssuecontentCallback ..."  if window.console
        if $(response).find("faultstring").text() is "Session is invalid"
            window.app.eventSystemNotLoggedIn()
        else
            if $(response).find("issueContentResult").text() is "true"
                @GetContentResources window.app.settings.currentBook
            else
                alert $(response).find("faultcode").text() + " - " + $(response).find("faultstring").text()

    ReturnContentCallBack: (response) =>
        console.log "PRO: ReturncontentCallback ..."  if window.console
        if $(response).find("faultstring").text() is "Session is invalid"
            window.app.eventSystemNotLoggedIn()
        else
            if $(response).find("returnContentResult").text() is "true"
                @GetBookShelf()
            else
                alert $(response).find("faultcode").text() + " - " + $(response).find("faultstring").text()

    GetContentResourcesCallBack: (response) =>
        console.log "PRO: Get content resources callback  - Bog ressourcer", response  if window.console
        @InitSystem()
        nccPath = ""
        if $(response).find("faultstring").text() is ""
            $(response).find("resource").each ->
                aHost = window.location.hostname
                dodpHost = $(this).attr("uri")
                aProtocol = dodpHost.substring(0, dodpHost.indexOf("/") + 2)
                dodpHost = dodpHost.substring(dodpHost.indexOf("/") + 2)
                dodpHost = dodpHost.substring(dodpHost.indexOf("/"))
                @DODPUriTranslate[$(this).attr("localURI")] = aProtocol + aHost + dodpHost
                temp = $(this).attr("uri")
                nccPath = aProtocol + aHost + dodpHost  if temp.indexOf("ncc.htm") isnt -1 and temp.substring(temp.length - 4, temp.length) isnt ".bak"
 
        else
            if $(response).find("faultcode").text() is "s:invalidParameterFault"
                alert $(response).find("faultstring").text()
                window.app.eventSystemEndLoading()
            else
                alert "Fejl i contentresourcescallback: " + $(response).find("faultstring").text()
        
        @GotBookFired = false
        unless @supports_local_storage()
            @CreateList nccPath
        else
            try
                window.app.book_tree = localStorage.getItem("NCC/" + window.app.settings.currentBook)
                if not window.app.book_tree? or window.app.book_tree is `undefined` or (window.app.book_tree.indexOf("ol") is -1)
                    @CreateList nccPath
                    try
                        @DeleteNccFromLocalStorage()  if localStorage.length > @MaxBooksInlocalStorage
                        localStorage.setItem "NCC/" + window.app.settings.currentBook, window.app.book_tree
                    catch e
                        localStorage.clear()  if e is QUOTA_EXCEEDED_ERR
            catch e
                alert "Error on retrieve NCC"
        if window.DOMParser
            try
                parser = new DOMParser()
                doc = parser.parseFromString(book_tree, "text/xml")
            catch e
                alert e.message
        else
            doc = new ActiveXObject("Microsoft.XMLDOM")
            doc.async = "false"
            doc.loadXML book_tree
        @PLAYLIST = doc.getElementsByTagName("li")
        @PrePareSmilNames @PLAYLIST[0], @smilCacheSize
        @CacheSmilFiles()

    LogOff: ->
        logOff_Soap = "<ns1:logOff></ns1:logOff>"
        $.ajax
            url: @DODP_URL
            headers: 
                SOAPAction: [ "/logOff" ]
            type: "POST"
            processData: true
            contentType: "text/xml; charset=utf-8"
            timeout: @DODP_DEFAULT_TIMEOUT
            dataType: "xml"
            data: @soapTemplate.replace("${soapBody}", logOff_Soap)
            cache: false
            success: @LogOffCallBack
            error: @OnError
            complete: @LogOffcompleteCallBack

    LogOn: (username, password) ->
        console.log "PRO: Log on: " + username + " | " + password  if window.console
        logOn_Soap = "<ns1:logOn><ns1:username>" + username + "</ns1:username><ns1:password>" + password + "</ns1:password></ns1:logOn>"
        $.ajax
            url: @DODP_URL
            headers:
              SOAPAction: [ "/logOn" ]
            type: "POST"
            processData: true
            contentType: "text/xml; charset=utf-8"
            timeout: @DODP_DEFAULT_TIMEOUT
            dataType: "xml"
            data: @soapTemplate.replace("${soapBody}", logOn_Soap)
            cache: false
            success: @LogOnCallBack
            error: @OnError
            complete: @LogOncompleteCallBack

    GetServiceAttributes: ->
        serviceAttributes_Soap = "<ns1:getServiceAttributes/>"
        $.ajax
            url: @DODP_URL
            headers:
              SOAPAction: [ "/getServiceAttributes" ]
            type: "POST"
            contentType: "text/xml; charset=utf-8"
            timeout: @DODP_DEFAULT_TIMEOUT
            dataType: "xml"
            data: @soapTemplate.replace("${soapBody}", serviceAttributes_Soap)
            cache: false
            success: @GetServiceAttributesCallBack
            error: @OnError
            complete: @GetServiceAttributescompleteCallBack

    SetReadingSystemAttributes: ->
        readingSystemAttributes_Soap = "<ns1:setReadingSystemAttributes><ns1:readingSystemAttributes><ns1:manufacturer>NOTA</ns1:manufacturer><ns1:model>LYT</ns1:model><ns1:serialNumber>1</ns1:serialNumber><ns1:version>1</ns1:version><ns1:config></ns1:config></ns1:readingSystemAttributes></ns1:setReadingSystemAttributes>"
        $.ajax
            url: @DODP_URL
            headers:
              SOAPAction: [ "/setReadingSystemAttributes" ]
            type: "POST"
            contentType: "text/xml; charset=utf-8"
            timeout: @DODP_DEFAULT_TIMEOUT
            dataType: "xml"
            data: @soapTemplate.replace("${soapBody}", readingSystemAttributes_Soap)
            cache: false
            success: @SetReadingSystemAttributesCallBack
            error: @OnError
            complete: @SetReadingSystemAttributescompleteCallBack

    GetServiceAnnouncements: ->
      getServiceAnnouncements_Soap = "<ns1:getServiceAnnouncements/>"
      $.ajax
        url: @DODP_URL
        headers:
          SOAPAction: [ "/getServiceAnnouncements" ]
        type: "POST"
        processData: true
        contentType: "text/xml; charset=utf-8"
        timeout: @DODP_DEFAULT_TIMEOUT
        dataType: "xml"
        data: @soapTemplate.replace("${soapBody}", getServiceAnnouncements_Soap)
        cache: false
        success: @GetServiceAnnouncementsCallBack
        error: @OnError
        complete: @GetServiceAnnouncementscompleteCallBack

    MarkAnnouncementsAsRead: (aId) ->
      MarkAnnouncementsAsRead_Soap = "<ns1:markAnnouncementsAsRead><ns1:read><ns1:item>" + aId + "</ns1:item></ns1:read></ns1:markAnnouncementsAsRead>"
      $.ajax
        url: @DODP_URL
        headers:
          SOAPAction: [ "/markAnnouncementsAsRead" ]
        type: "POST"
        contentType: "text/xml; charset=utf-8"
        timeout: @DODP_DEFAULT_TIMEOUT
        dataType: "xml"
        data: @soapTemplate.replace("${soapBody}", MarkAnnouncementsAsRead_Soap)
        cache: false
        success: @MarkAnnouncementsAsReadCallBack
        error: @OnError
        complete: @MarkAnnouncementsAsReadcompleteCallBack


    GetContentList: (listName, firstItem, lastItem) ->
      console.log "PRO: Henter boghylde..."  if window.console
      GetContentList_Soap = "<ns1:getContentList><ns1:id>" + listName + "</ns1:id><ns1:firstItem>" + firstItem + "</ns1:firstItem><ns1:lastItem>" + lastItem + "</ns1:lastItem></ns1:getContentList>"
      $.ajax
        url: @DODP_URL
        headers:
          SOAPAction: [ "/getContentList" ]
        type: "POST"
        contentType: "text/xml; charset=utf-8"
        timeout: @DODP_DEFAULT_TIMEOUT
        dataType: "xml"
        data: @soapTemplate.replace("${soapBody}", GetContentList_Soap)
        cache: false
        success: @GetContentListCallBack
        error: @OnError
        complete: @GetContentListcompleteCallBack


    IssueContent: (bookId) ->
      console.log "PRO: Issue content: bookid: ", bookId  if window.console
      IssueContent_Soap = "<ns1:issueContent><ns1:contentID>" + bookId + "</ns1:contentID></ns1:issueContent>"
      $.ajax
        url: @DODP_URL
        headers:
          SOAPAction: [ "/issueContent" ]
        type: "POST"
        contentType: "text/xml; charset=utf-8"
        timeout: @DODP_DEFAULT_TIMEOUT
        dataType: "xml"
        data: @soapTemplate.replace("${soapBody}", IssueContent_Soap)
        cache: false
        success: @IssueContentCallBack
        error: @OnError
        complete: @IssueContentcompleteCallBack


    ReturnContent: (bookId) ->
      console.log "PRO: return content: bookid: ", bookId  if window.console
      ReturnContent_Soap = "<ns1:returnContent><ns1:contentID>" + bookId + "</ns1:contentID></ns1:returnContent>"
      $.ajax
        url: @DODP_URL
        headers:
          SOAPAction: [ "/returnContent" ]
        type: "POST"
        contentType: "text/xml; charset=utf-8"
        timeout: @DODP_DEFAULT_TIMEOUT
        dataType: "xml"
        data: @soapTemplate.replace("${soapBody}", ReturnContent_Soap)
        cache: false
        success: @ReturnContentCallBack
        error: @OnError
        complete: @ReturnContentcompleteCallBack


    GetContentMetadata: (aId) ->
      ContentMetadata_Soap = "<ns1:getContentMetadata><ns1:contentID>" + aId + "</ns1:contentID></ns1:getContentMetadata>"
      $.ajax
        url: @DODP_URL
        headers:
          SOAPAction: [ "/getContentMetadata" ]
        type: "POST"
        processData: true
        contentType: "text/xml; charset=utf-8"
        timeout: @DODP_DEFAULT_TIMEOUT
        dataType: "xml"
        data: @soapTemplate.replace("${soapBody}", ContentMetadata_Soap)
        cache: false
        success: @GetContentMetadataCallBack
        error: @OnError
        complete: @GetContentMetadatacompleteCallBack


    GetContentResources: (aId) ->
      console.log "PRO: Kalder get content ressources..."  if window.console
      ContentResources_Soap = "<ns1:getContentResources><ns1:contentID>" + aId + "</ns1:contentID></ns1:getContentResources>"
      $.ajax
        url: @DODP_URL
        headers:
          SOAPAction: [ "/getContentResources" ]
        type: "POST"
        contentType: "text/xml; charset=utf-8"
        timeout: @DODP_DEFAULT_TIMEOUT
        dataType: "xml"
        data: @soapTemplate.replace("${soapBody}", ContentResources_Soap)
        cache: false
        success: @GetContentResourcesCallBack
        error: @OnError
        complete: @GetContentResourcescompleteCallBack


    SetBookmarks: (aId, BookMarksXml) ->
      bookmarks_Soap = "<ns1:setBookmarks><ns1:contentID>" + aId + "</ns1:contentID>" + BookMarksXml + "</ns1:setBookmarks>"
      $.ajax
        url: @DODP_URL
        headers:
          SOAPAction: [ "/setBookmarks" ]
        type: "POST"
        processData: true
        contentType: "text/xml; charset=utf-8"
        timeout: @DODP_DEFAULT_TIMEOUT
        dataType: "xml"
        data: @soapTemplate.replace("${soapBody}", bookmarks_Soap)
        cache: false
        success: @SetBookmarksCallBack
        error: @OnError
        complete: @SetBookmarkscompleteCallBack

    GetBookmarksSync: (aId) ->
      bookmarkXml = $("<bookmarkSet>")
      t = $("<title>")
      bookmarkXml.append t
      text = $("<text>")
      text.append aId
      t.append text
      t.append $("<audio>")
      uid = $("<uid>")
      uid.append aId
      bookmarkXml.append uid
      last = $("<lastmark>")
      bookmarkXml.append last
      ncxref = $("<ncxRef>")
      ncxref.append "xyub00066"
      last.append ncxref
      URI = $("<URI>")
      URI.append "cddw000A.smil#xyub00066"
      last.append URI
      timeOffset = $("<timeOffset>")
      timeOffset.append "00:10.0"
      last.append timeOffset
      bookmarkXml

    GetBookShelf: ->
      @GetContentList "issued", "0", "-1"

    GetBook: (bookId) ->
      console.log "PRO: PRO: Getbook: bookid: ", bookId  if window.console
      @IssueContent bookId

    GetBookmarks: (aId) ->
      @GetBookmarksSync aId

    CreateList: (urlToBookNcc) ->
      console.log "PRO: Creating list from: " + urlToBookNcc
      $.ajax
        url: urlToBookNcc
        type: "GET"
        dataType: "xml"
        async: false
        success: @CreateListCallback
        error: @OnError

    CreateListCallback: (xml) =>
        console.log "PRO: Create list callback", xml
        string = ""
        currentlevel = 1
        formerlevel = 1
        difference = 0
        savedforlater = undefined
        me = ""
        forfatter = undefined
    
        try
            totalTime = xml.getElementsByName("ncc:totalTime")[0].getAttribute("content")
        unless xml.getElementsByName("dc:creator").length is 0
            forfatter = xml.getElementsByName("dc:creator")[0].getAttribute("content")
        else
            forfatter = "NN"
            title = xml.getElementsByName("dc:title")[0].getAttribute("content")
    	    $(xml).find(":header").each (i) ->
                currentlevel = @nodeName.toLowerCase().substr(1, 2)
                me = "<li id=\"" + $(this).attr("id") + "\" xhref=\"" + $(this).find("a").attr("href") + "\">" + $(this).find("a").text() + "</li>"
                if formerlevel - currentlevel < 0
                    string = string.slice(0, (string.length - 5))
                    string += "<ol>" + me
                if formerlevel - currentlevel > 0
                    i = 0
                    while i < formerlevel - currentlevel
                        string += "</ol></li>"
                        i++
                    string += me
           
                string += me  if formerlevel - currentlevel is 0
                formerlevel = @nodeName.toLowerCase().substr(1, 2)
            
                if currentlevel > 1
                    i = 1
                    while i < currentlevel
                        string += "</ol></li>"
                        i++
                else
                    string += "</li>"
                    string = "<ul titel=\"" + title + "\" forfatter=\"" + forfatter + "\" totalTime=\"" + totalTime + "\" id=\"NccRootElement\" data-role=\"listview\">" + string + "</ol>"
                    book_tree = string
    
        console.log "PRO: NCC liste oversat til li..."  if window.console

    PrePareSmilNames: (node, count) ->
      console.log "PRO: Prepare smile names"  if window.console
      j = @findNode(node, @PLAYLIST)
      unless j is -1
        i = j
        while i < @PLAYLIST.length
          if (i - j) < count
            temp = @PLAYLIST[i].getAttribute("xhref").substring(@PLAYLIST[i].getAttribute("xhref").lastIndexOf("/") + 1, @PLAYLIST[i].getAttribute("xhref").indexOf("#"))
            @smilNamestoBeAdded.push temp
          i++

    DeleteNccFromLocalStorage: ->
      try
        j = 0
        while j < localStorage.length
          unless localStorage.key(j).indexOf("NCC/") is -1
            localStorage.removeItem localStorage.key(j)
            break
          j++
      catch e
        alert e.message

    CacheSmilFiles: ->
      console.log "PRO: Caching smile files"  if window.console
      try
        xmlHttp1 = new XMLHttpRequest()
      catch e
        try
          xmlHttp1 = new ActiveXObject("Msxml2.XMLHTTP")
        catch e
          try
            xmlHttp1 = new ActiveXObject("Microsoft.XMLHTTP")
          catch e
            alert "Your browser does not support AJAX!"
            return false
      xmlHttp1.onreadystatechange = ->
        if xmlHttp1.readyState is 4
          if @smilNamestoBeAdded.length > 0
            if @smilFilesInBuffer >= @smilCacheSize
              i = 0

              while i < @smilNamestoBeAdded.length
                delete @smilCacheTable[@smilCacheTableGetKey(i)]

                @smilFilesInBuffer--
                i++
            @currentSmilFile = @smilNamestoBeAdded.shift()
            try
              @smilCacheTable[@currentSmilFile] = xmlHttp1.responseXML
              @smilCacheTable[@currentSmilFile] = -1  unless xmlHttp1.status is 200
              @smilFilesInBuffer++
              @GetHtmlName @smilCacheTable[@currentSmilFile]  if @smilFilesInBuffer is 1
              @CacheSmilFiles()
            catch e
              @smilCacheError = true

      if @smilNamestoBeAdded.length > 0
        xmlHttp1.overrideMimeType "text/xml"  if xmlHttp1.overrideMimeType
        xmlHttp1.open "GET", @DODPUriTranslate[@smilNamestoBeAdded[0]], true
        xmlHttp1.send null

    CacheSmilFilesSync: ->
      try
        xmlHttp3 = new XMLHttpRequest()
      catch e
        try
          xmlHttp3 = new ActiveXObject("Msxml2.XMLHTTP")
        catch e
          try
            xmlHttp3 = new ActiveXObject("Microsoft.XMLHTTP")
          catch e
            alert "Your browser does not support AJAX!"
            return false
      if @smilNamestoBeAdded.length > 0
        xmlHttp3.overrideMimeType "text/xml"  if xmlHttp3.overrideMimeType
        xmlHttp3.open "GET", @DODPUriTranslate[@smilNamestoBeAdded[0]], false
        xmlHttp3.send null
        if @smilFilesInBuffer >= @smilCacheSize
          i = 0

          while i < @smilNamestoBeAdded.length
            delete @smilCacheTable[@smilCacheTableGetKey(i)]

            @smilFilesInBuffer--
            i++
        @currentSmilFile = @smilNamestoBeAdded.shift()
        try
          @smilCacheTable[@currentSmilFile] = xmlHttp3.responseXML
          @smilCacheTable[@currentSmilFile] = -1  unless xmlHttp3.status is 200
          @smilFilesInBuffer++
          @GetHtmlName @smilCacheTable[@currentSmilFile]  if @smilFilesInBuffer is 1
        catch e
          @smilCacheError = true

    smilCacheTableGetKey: (aIndex) ->
      i = 0
      for n of @smilCacheTable
        return n  if i is aIndex
        i++

    smilCacheTableGetIndex: (aKey) ->
      i = 0
      for n of @smilCacheTable
        return i  if n is aKey
        i++

    findNode: (node, list) ->
      returnV = -1
      try
        i = 0
        while i < list.length
          returnV = i  if node.getAttribute("xhref") is list[i].getAttribute("xhref")
          i++
      returnV

    CacheHtmlFile: (htmlfileName, localname) ->
      xmlHttp = undefined
      try
        xmlHttp = new XMLHttpRequest()
      catch e
        try
          xmlHttp = new ActiveXObject("Msxml2.XMLHTTP")
        catch e
          try
            xmlHttp = new ActiveXObject("Microsoft.XMLHTTP")
          catch e
            alert "Your browser does not support AJAX!"
            return false
      xmlHttp.onreadystatechange = ->
        if xmlHttp.readyState is 3
          if @firstHtmlFilePart.length <= @sizeOfFirstHtmlFilePart
            @firstHtmlFilePart = xmlHttp.responseText
          else unless @GotBookFired
            window.app.eventSystemGotBook book_tree
            @GotBookFired = true
        if xmlHttp.readyState is 4
          @htmlCacheTable[localname] = xmlHttp.responseXML
          @ReplaceLocalURIInHtml @htmlCacheTable[localname]
          unless @GotBookFired
            window.app.eventSystemGotBook book_tree
            @GotBookFired = true

      if xmlHttp.overrideMimeType
        xmlHttp.overrideMimeType "text/xml"
        xmlHttp.open "GET", htmlfileName, true
        xmlHttp.send null
      else
        xmlDoc1 = undefined
        xmlDoc1 = new ActiveXObject("Microsoft.XMLDOM")
        xmlDoc1.async = "false"
        try
          xmlDoc1.load htmlfileName
          @htmlCacheTable[localname] = xmlDoc1
          @ReplaceLocalURIInHtml @htmlCacheTable[localname]
        catch e
          alert e.message

    GetHtmlName: (smilfileXml) ->
      console.log "PRO: GetHtmlName"  if window.console
      unless smilfileXml.getElementsByTagName("text").length is 0
        htmlFileName = smilfileXml.getElementsByTagName("text")[0].getAttribute("src")
        htmlFileName = htmlFileName.substring(0, htmlFileName.indexOf("#"))
        @CacheHtmlFile @DODPUriTranslate[htmlFileName], htmlFileName
      else
        alert "ingen text"

    ReplaceLocalURIInHtml: (html) ->
      $(html).find("img").each ->
        $(this).attr "src", @DODPUriTranslate[$(this).attr("src")]

    supports_local_storage: ->
      try
        return true  if window["localStorage"]?
      catch e
        return false

    GetTextAndSound: (aElement) ->
      if Player.isSystemEvent
        Player.isSystemEvent = false
      else
        Player.isUserEvent = true
      try
        @currentAElement = aElement
        @nextAElement = @GetNextAElement(aElement)
        smilfile = aElement.getAttribute("xhref").substring(aElement.getAttribute("xhref").lastIndexOf("/") + 1, aElement.getAttribute("xhref").indexOf("#"))
        @currentSmilFile = smilfile
        smilid = aElement.getAttribute("xhref").substr(aElement.getAttribute("xhref").indexOf("#") + 1)
        if @smilCacheTable[smilfile] is `undefined`
          p = @findNode(aElement, @PLAYLIST)
          @PrePareSmilNames @PLAYLIST[p], 1
          @CacheSmilFilesSync()
          @GetTextAndSound aElement
        else if @smilCacheError
          alert "There is a problem with the cache"
        else
          window.globals.text_window.innerHTML = ""
          pos = @smilCacheTableGetIndex(smilfile)
          if pos > @smilCacheTrigger
            p = @findNode(aElement, @PLAYLIST) + (@smilCacheSize - pos)
            @PrePareSmilNames @PLAYLIST[p], @smilFilesToCache
            @CacheSmilFiles()
          @soundfilename = @smilCacheTable[smilfile].getElementsByTagName("audio")[0].getAttribute("src")
          @nextSoundFileName = @GetNextSoundFileName(@smilCacheTable[smilfile], smilfile)
          @tempTextList = @smilCacheTable[smilfile].getElementsByTagName("text")
          @textTagList.length = 0
          i = 0
          while i < @tempTextList.length
            @textTagList[i] = @tempTextList[i]
            i++
          @GetAllTheText = true  if window.app.settings.textMode is 2
          unless Player.LastPartNCCJump
            @currentTimeInSmil = @smilCacheTable[smilfile].getElementsByName("ncc:totalElapsedTime")[0].getAttribute("content")
            @SetTotalSeconds @currentTimeInSmil
            @GetTextAndSoundPiece smilid, @smilCacheTable[smilfile]
            @textTagList.shift()
          else
            Player.LastPartNCCJump = false
      catch e
        return false

    GetNextAElement: (aElement) ->
      try
        i = 0
        while i < @PLAYLIST.length
          return @PLAYLIST.item(i + 1)  if @PLAYLIST[i].getAttribute("xhref") is aElement.getAttribute("xhref")
          i++
        return null
      catch e
        return null

    GetLastAElement: (aElement) ->
      try
        i = 0
        while i < @PLAYLIST.length
          return @PLAYLIST.item(i - 1)  if @PLAYLIST[i].getAttribute("xhref") is aElement.getAttribute("xhref")
          i++
        return null
      catch e
        return null

    GetNextSoundFileName: (smilCacheEntry, smilname) ->
      found = false
      try
        tempList = smilCacheEntry.getElementsByTagName("audio")
        unless tempList.length is 0
          i = 0
          while i < tempList.length
            unless tempList[i].getAttribute("src") is @soundfilename
              @soundfilename = tempList[i].getAttribute("src")
              found = true
              break
            i++
          unless found
            aIndex = undefined
            aIndex = @smilCacheTableGetIndex(smilname)
            if aIndex < @smilCacheSize
              temp = @smilCacheTableGetKey(aIndex + 1)
              unless @smilCacheTable[temp] is `undefined`
                @GetNextSoundFileName @smilCacheTable[temp], temp
              else
                @soundfilename = ""
      catch e
        alert e.message
      @soundfilename

    GetTextAndSoundPiece: (aSmilId, smilfileXml) ->
      try
        switch smilfileXml.nodeType
          when 1
            switch smilfileXml.nodeName.toUpperCase()
              when "TEXT"
                id = $(smilfileXml).attr("id")
                if window.app.settings.textMode is 1
                  if id is aSmilId
                    temp = smilfileXml.getAttribute("src")
                    GetText temp.substring(0, temp.indexOf("#")), temp.substr(temp.indexOf("#") + 1)
                    tempList = smilfileXml.parentNode.getElementsByTagName("audio")
                    i = 0

                    while i < tempList.length
                      @audioTagList[i] = tempList[i]
                      i++
                    audio = @audioTagList.shift()
                    @GetSound @DODPUriTranslate[audio.getAttribute("src")], audio.getAttribute("clip-begin"), audio.getAttribute("clip-end")
                else
                  if @GetAllTheText
                    temp = smilfileXml.getAttribute("src")
                    GetText temp.substring(0, temp.indexOf("#")), temp.substr(temp.indexOf("#") + 1)
                  if id is aSmilId
                    tempList = smilfileXml.parentNode.getElementsByTagName("audio")
                    i = 0

                    while i < tempList.length
                      @audioTagList[i] = tempList[i]
                      i++
                    audio = @audioTagList.shift()
                    @GetSound @DODPUriTranslate[audio.getAttribute("src")], audio.getAttribute("clip-begin"), audio.getAttribute("clip-end")
              else
          else
        i = 0

        while i < smilfileXml.childNodes.length
          @GetTextAndSoundPiece aSmilId, smilfileXml.childNodes[i]
          i++
      catch e
        alert e.message
    
    FindEndTag: (html, startPoint) ->
      try
        html = html.substr(startPoint)
        @GlobalCount += html.indexOf("<")
        @FindEndTag html, html.indexOf("<") + 1  if html.substring(html.indexOf("<") + 1, html.indexOf("<") + 2) is "/"
      catch e
        alert e.message

    updateTime: (currentTime) ->
      try
        window.app.eventSystemTime currentTime + @totalsec
      catch e
        alert e.message

    SetTotalSeconds: (total) ->
      @totalsec = parseInt(total.substr(0, 2), 10) * 60 * 60
      @totalsec = @totalsec + (parseInt(total.substr(3, 2), 10) * 60)
      @totalsec = @totalsec + parseInt(total.substr(6, 2), 10)

    SecToTime: (aTime) ->
      temp = undefined
      houers = undefined
      min = undefined
      sec = undefined
      houers = (aTime / 60) / 60
      houers = houers.toString()
      min = houers.substring(houers.indexOf("."), (houers.length - 1) - houers.indexOf("."))
      min = "0" + min
      min = min * 60
      min = min.toString()
      sec = min.substring(min.indexOf("."), (min.length - 1) - min.indexOf("."))
      sec = "0" + sec
      sec = sec * 60
      sec = sec.toString()
      houers = houers.substring(0, houers.indexOf("."))
      min = min.substring(0, min.indexOf("."))
      sec = sec.substring(0, sec.indexOf("."))
      houers = "0" + houers  if houers.length < 2
      min = "0" + min  if min.length < 2
      sec = "0" + sec  if sec.length < 2
      temp = houers + ":" + min + ":" + sec
      temp

    GetText: (htmlfileName, aId) ->
      try
        if @htmlCacheTable[htmlfileName] isnt `undefined` or @htmlCacheTable[htmlfileName]?
          html = @htmlCacheTable[htmlfileName]
          parameter = "//*[@id='" + aId + "']"
          if document.evaluate
            part = html.evaluate(parameter, html, null, XPathResult.ANY_TYPE, null)
            node = part.iterateNext()
            window.app.eventSystemTextChanged "", node, "", @currentAElement.firstChild.nodeValue
          else
            temp = null
            t = $(@htmlCacheTable[htmlfileName])
            t.find("*").each ->
              temp = document.createTextNode($(this).text())  if $(this).attr("id") is aId

            window.app.eventSystemTextChanged "", temp, "", @currentAElement.firstChild.nodeValue
        else
          unless @firstHtmlFilePart.indexOf(aId) is -1
            temp1 = @firstHtmlFilePart.substring(0, @firstHtmlFilePart.indexOf(aId))
            startTemp = temp1.lastIndexOf("<")
            temp2 = @firstHtmlFilePart.substr(@firstHtmlFilePart.indexOf(aId))
            stopTemp = temp2.indexOf("</")
            @GlobalCount = 0
            @FindEndTag temp2, stopTemp
            htmlPart = @firstHtmlFilePart.substring(startTemp, temp1.length + stopTemp + @GlobalCount)
            temp = document.createTextNode($(htmlPart).text())
            window.app.eventSystemTextChanged "", temp, "", @currentAElement.firstChild.nodeValue
      catch e
        alert e.message

    GetSound: (UrlToSound, aStart, aEnd) ->
      if Player.player.canPlayType("audio/mpeg") is ""
        alert "kan ikke afspille mp3 format"
        return
      if Player.userPaused
        @rememberSoundFile[0] = UrlToSound
        @rememberSoundFile[1] = aStart
        @rememberSoundFile[2] = aEnd
        return
      try
        clearInterval Player.BeginPolling
        if Player.player.src.indexOf(UrlToSound) is -1
          if Player.isCached(UrlToSound)
            Player.SwitchPlayer()
          else
            console.log "PRO: Requesting next sound file " + UrlToSound
            @LogOn window.app.settings.username, window.app.settings.password
            Player.player.src = UrlToSound
            Player.player.preload = "metadata"
            Player.player.load()
          unless @nextSoundFileName is ""
            console.log "PRO: caching next sondfile" + @nextSoundFileName
            @LogOn window.app.settings.username, window.app.settings.password
            Player.CacheNextSoundFile @DODPUriTranslate[@nextSoundFileName]
        @clipBegin = aStart.slice(4, -1)
        @clipBegin = parseFloat(@clipBegin)
        unless Player.player.readyState is 0
          try
            if @clipBegin isnt Player.stopTime or Player.player.currentTime < Player.stopTime
              Player.player.pause()
              Player.player.currentTime = @clipBegin
              setTimeout "Player.player.play()", 500  if @clipBegin is 0
            else
              Player.player.play()  if Player.player.paused
        @clipEnd = aEnd.slice(4, -1)
        @clipEnd = parseFloat(@clipEnd)
        Player.startTime = @clipBegin
        Player.stopTime = @clipEnd
        Player.BeginPolling = setInterval("Player.CheckEndTime()", 50)
      catch e
        alert e.message

    eventSystemPaused: ->
      try
        if @audioTagList.length > 0
          audio = @audioTagList.shift()
          @GetSound @DODPUriTranslate[audio.getAttribute("src")], audio.getAttribute("clip-begin"), audio.getAttribute("clip-end")
        else if @textTagList.length > 0
          aTextTag = @textTagList.shift()
          @GetAllTheText = false
          @GetTextAndSoundPiece aTextTag.getAttribute("id"), @smilCacheTable[@currentSmilFile]
        else if @nextAElement?
          Player.isSystemEvent = true
          @GetTextAndSound @nextAElement
      catch e
        alert e.message

    InitSystem: ->
      @DODPUriTranslate = new Object()
      @smilCacheTable = new Object()
      @smilNamestoBeAdded = new Array()
      @rememberSoundFile = new Array()
      @smilFilesInBuffer = 0
      @htmlCacheTable = new Object()
      @firstHtmlFilePart = ""
      @GotBookFired = false
      @audioTagList = new Array()
      @textTagList = new Array()
      @smilCacheError = false
      @currentSmilFile = ""
      @currentAElement = null
      @nextAElement = null
      @nextSoundFileName = ""
      @currentTimeInSmil = ""
      @totalsec = 0
      ###
      This shouldn't be in the fileinterface class, but defaults in the player.
      Pause()
      Player.player.startTime = 0
      Player.player.stopTime = 0
      Player.player.BeginPolling = 0
      Player.player.LastPartNCCJump = false
      Player.player.userPaused = false
      ###

window.FileInterface = FileInterface