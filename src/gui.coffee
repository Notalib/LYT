# work in progress, nothing is really working here

LYT.gui:
  
  goto: "bookshelf"
  
  covercache: (element) ->
    $(element).each ->
      id = $(this).attr("id")
      u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg"
      img = $(new Image()).load(->
        $("#" + id).find("img").attr "src", u
      ).error(->
      ).attr("src", u)

  covercache_one: (element) ->
    id = $(element).find("img").attr("id")
    u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg"
    img = $(new Image()).load(->
      $(element).find("img").attr "src", u
    ).error(->
    ).attr("src", u)
  
  parse_media_name: (mediastring) ->
    unless mediastring.indexOf("AA") is -1
      "Lydbog"
    else
      "Lydbog med tekst"

  onBookDetailsSuccess: (data, status) ->
      $("#book-details-image").html "<img id=\"" + data.d[0].imageid + "\" class=\"nota-full\" src=\"/images/default.png\" />"
      s = ""
      s = "<p>Serie: " + data.d[0].series + ", del " + data.d[0].seqno + " af " + data.d[0].totalcnt + "</p>"  if data.d[0].totalcnt > 1
      $("#book-details-content").empty()
      $("#book-details-content").append("<h2>" + data.d[0].title + "</h2>" + "<h4>" + data.d[0].author + "</h4>" + "<a href=\"javascript:PlayNewBook(" + data.d[0].imageid + ", '" + data.d[0].title.replace("'", "") + "','" + data.d[0].author + "')\" data-role=\"button\" data-inline=\"true\">Afspil</a>" + "<p>" + parse_media_name(data.d[0].media) + "</p>" + "<p>" + data.d[0].teaser + "</p>" + s).trigger "create"
      @covercache_one $("#book-details-image")

  onBookDetailsError: (msg, data) ->
      $("#book-details-image").html "<img src=\"/images/default.png\" />"
      $("#book-details-content").html "<h2>Hov!</h2>" + "<p>Der skulle have været en bog her - men systemet kan ikke finde den. Det beklager vi meget! <a href=\"mailto:info@nota.nu?subject=Bog kunne ikke findes på E17 mobilafspiller\">Send os gerne en mail om fejlen</a>, så skal vi fluks se om det kan rettes.</p>"

  onSearchSuccess: (data, status) ->
      s = ""
      unless data.d[0].resultstatus is "NORESULTS"
          s += "<li><h3>" + data.d[0].totalcount + " resultat(er)</h3></li>"
          $.each data.d, (index, item) ->
              s += "<li id=\"" + item.imageid + "\"><a href=\"#book-details\">" + "<img class=\"ui-li-icon\" src=\"/images/default.png\" /><h3>" + item.title + "</h3><p>" + item.author + " | " + parse_media_name(item.media) + "</p></a></li>"
      else
          s += "<li><h3>Ingen resultater</h3><p>Prøv eventuelt at bruge bredere søgeord. For at teste funktionen, søg på et vanligt navn, såsom \"kim\" eller \"anders\".</p></li>"
          $("#searchresult").html s

  onSearchError = (msg, data) ->
      $("#searchresult").text "Error thrown: " + msg.status

  onSearchComplete: ->
      $("#searchresult").listview "refresh"
      $("#searchresult").find("a:first").css "padding-left", "40px"
      $.mobile.hidePageLoadingMsg()
      @covercache $("#searchresult").html()

  PlayNewBook: (id, title, author) ->
      $.mobile.showPageLoadingMsg()
      Pause()
      @settings.currentBook = id.toString()
      @settings.currentTitle = title
      @settings.currentAuthor = author
      @SetSettings()
      $("#currentbook_image").find("img").attr("src", "/images/default.png").trigger "create"
      $("#currentbook_image").find("img").attr("id", @settings.currentBook).trigger "create"
      $("#book_title").text title
      $("#book_author").text author
      $("#book_chapter").text 0
      $("#book_time").text 0
      $.mobile.showPageLoadingMsg()
      window.fileInterface.GetBook @settings.currentBook
      Play()

  eventSystemLoggedOn: (loggedOn, id) ->
      unless id is -1
          @settings.username = id
          @SetSettings()
      if loggedOn
          console.log "GUI: Event system logged on - kalder goto " + @goto
          @gotoPage()
      else
          $.mobile.hidePageLoadingMsg()
          $.mobile.changePage "#login"

  eventSystemLoggedOff: (LoggedOff) ->
      console.log "GUI: Event system logged off"  if console
      $.mobile.hidePageLoadingMsg()
      @goto = "bookshelf"
      $.mobile.changePage "#login"  if LoggedOff

  eventSystemNotLoggedIn: (where) ->
      @goto = where
      if @settings.username isnt "" and @settings.password isnt ""
          console.log "GUI: Event system not logged in, logger på i baggrunden"  if console
          window.fileInterface.LogOn @settings.username, @settings.password
      else
          $.mobile.changePage "#login"

  eventSystemForceLogin: (response) ->
      alert response
      $.mobile.hidePageLoadingMsg()
      $.mobile.changePage "#login"

  eventSystemGotBook: (bookTree) ->
      $.mobile.hidePageLoadingMsg()
      $("#book-play #book-text-content").html window.globals.text_window
      GetTextAndSound PLAYLIST[0]
      $("#book_index_content").empty()
      $("#book_index_content").append bookTree
      $.mobile.changePage "#book-play"

  eventSystemGotBookShelf: (bookShelf) =>
      @goto = ""
      @full_bookshelf = bookShelf
      console.log @full_bookshelf
      $("#bookshelf-content").empty()
      aBookShelf = ""
      nowPlaying = ""
      addMore = ""
      $(bookShelf).find("contentItem:lt(" + @bookshelf_showitems + ")").each =>        
          delimiter = $(this).text().indexOf("$")
          author = $(this).text().substring(0, delimiter)
          title = $(this).text().substring(delimiter + 1)
          if $(this).attr("id") is @settings.currentBook
              nowPlaying = "<li id=\"" + $(this).attr("id") + "\" title=\"" + title.replace("'", "") + "\" author=\"" + author + "\" ><a href=\"javascript:playCurrent();\"><img class=\"ui-li-icon\" src=\"/images/default.png\" />" + "<h3>" + title + "</h3><p>" + author + " | afspiller nu</p></a></li>"
          else
              aBookShelf += "<li id=\"" + $(this).attr("id") + "\" title=\"" + title.replace("'", "") + "\" author=\"" + author + "\"><a href='javascript:PlayNewBook(" + $(this).attr("id") + ", \" " + title.replace("'", "") + " \" , \" " + author + " \")'><img class=\"ui-li-icon\" src=\"/images/default.png\" />" + "<h3>" + title + "</h3><p>" + author + "</p></a><a href=\"javascript:if(confirm('Fjern " + title.replace("'", "") + " fra din boghylde?')){ReturnContent(" + $(this).attr("id") + ");}\" >Fjern fra boghylde</a></li>"

      addMore = "<li id=\"bookshelf-end \"><a href=\"javascript:addBooks()\">Hent flere bøger på min boghylde</p></li>"  if $(@full_bookshelf).find("contentList").attr("totalItems") > @bookshelf_showitems
      $.mobile.changePage "#bookshelf"
      $("#bookshelf-content").append("<ul data-split-icon=\"delete\" data-split-theme=\"d\" data-role=\"listview\" id=\"bookshelf-list\">" + nowPlaying + aBookShelf + addMore + "</ul>").trigger "create"
      @covercache $("#bookshelf-list").html()

  addBooks: ->
      @bookshelf_showitems += 5
      @eventSystemGotBookShelf @full_bookshelf

  eventSystemPause: (aType) ->
      $("#button-play").find("img").attr("src", "/images/play.png").trigger "create"
      if aType is Player.Type.user

      else aType is Player.Type.system

  eventSystemPlay: (aType) ->
      $("#button-play").find("img").attr("src", "/images/pause.png").trigger "create"
      if aType is Player.Type.user

      else aType is Player.Type.system

  eventSystemTime: (t) ->
      total_secs = undefined
      current_percentage = undefined
      if $("#NccRootElement").attr("totaltime")?
          tt = $("#NccRootElement").attr("totaltime")
          total_secs = tt.substr(0, 2) * 3600 + (tt.substr(3, 2) * 60) + parseInt(tt.substr(6, 2))  if tt.length is 8
          total_secs = tt.substr(0, 1) * 3600 + (tt.substr(2, 2) * 60) + parseInt(tt.substr(5, 2))  if tt.length is 7
          total_secs = tt.substr(0, 2) * 3600 + (tt.substr(3, 2) * 60)  if tt.length is 5
      current_percentage = Math.round(t / total_secs * 98)
      $("#current_time").text SecToTime(t)
      $("#total_time").text $("#NccRootElement").attr("totaltime")
      $("#timeline_progress_left").css "width", current_percentage + "%"

  eventSystemTextChanged: (textBefore, currentText, textAfter, chapter) ->
      try
          window.globals.text_window.innerHTML = ""
          chapter = "Kapitel"  if chapter is "" or not chapter?
          chapter = chapter.substring(0, 14) + "..."  if chapter.length > 14
          $("#book_chapter").text chapter
          unless currentText.nodeType is `undefined`
              window.globals.text_window.appendChild document.importNode(currentText, true)
              $("#book-text-content").find("img").each ->
                  rep_src = $(this).attr("src").replace(/\\/g, "\\\\")
                  oldimage = $(this)
                  img = $(new Image()).load(->
                      $(oldimage).replaceWith $(this)
                      $(oldimage).attr "src", $(this).attr("src")
                      $(this).css "max-width", "100%"
                      position = $(this).position()
                      $.mobile.silentScroll position.top
                  ).error(->
                  ).attr("src", rep_src)

              $("#book-text-content h1 a, #book-text-content h2 a").css("color", @settings.markingColor.substring(@settings.markingColor.indexOf("-", 0) + 1)).trigger "create"
          else
      catch e
          alert e

  eventSystemStartLoading: ->
      $.mobile.showPageLoadingMsg()

  eventSystemEndLoading: ->
      $.mobile.hidePageLoadingMsg()

  showIndex: ->
      $.mobile.changePage "#book_index"

  playCurrent: ->
      if isPlayerAlive()
        $.mobile.changePage "#book-play"
      else
        @PlayNewBook @settings.currentBook, @settings.currentTitle, @settings.currentAuthor

  setDestination: (where) =>
      @goto = where

  gotoPage: ->
      console.log "GUI: gotoPage - " + @goto  if console
      switch @goto
          when "bookshelf"
              window.fileInterface.GetBookShelf()
              @goto = ""
          else
              window.fileInterface.GetBookShelf()  if $(".ui-page-active").attr("id") is "login"

  logUserOff: ->
      @settings.username = ""
      @settings.password = ""
      @SetSettings()
      window.fileInterface.LogOff()
  
  setup: ->
    $("#login").live "pagebeforeshow", (event) ->
      $("#login-form").submit (event) ->
        @goto = "bookshelf"
        $.mobile.showPageLoadingMsg()
        $("#password").blur()
        event.preventDefault()
        event.stopPropagation()
    
        @settings.set('username') = $("#username").val()  if $("#username").val().length < 10
        @settings.set('password') = $("#password").val()

        @protocol.LogOn $("#username").val(), $("#password").val()

    $("#book_index").live "pagebeforeshow", (event) ->
       $("#book_index_content").trigger "create"
           $("li[xhref]").bind "click", (event) ->
             $.mobile.showPageLoadingMsg()
             if ($(window).width() - event.pageX > 40) or (typeof $(this).find("a").attr("href") is "undefined")
                if $(this).find("a").attr("href")
                    event.preventDefault()
                    event.stopPropagation()
                    event.stopImmediatePropagation()
                    #window.fileInterface.GetTextAndSound this
                    $.mobile.changePage "#book-play"
                else
                    event.stopImmediatePropagation()
                    $.mobile.changePage $(this).find("a").attr("href")

    $("#book-play").live "pagebeforeshow", (event) ->
        console.log "afspiller nu - " + isPlayerAlive()
        unless isPlayerAlive()
            @goto = "bookshelf"
            @gotoPage()
        window.app.covercache_one $("#book-middle-menu")
        $("#book-text-content").css "background", @settings.get('markingColor').substring( @settings.get('markingColor').indexOf("-", 0))
        $("#book-text-content").css "color", @settings.get('markingColor').substring( @settings.get('markingColor').indexOf("-", 0) + 1)
        $("#book-text-content").css "font-size",  @settings.get('textSize') + "px"
        $("#book-text-content").css "font-family",  @settings.get('textType')
        $("#bookshelf [data-role=header]").trigger "create"

        $("#book-play").bind "swiperight", ->
            NextPart()

        $("#book-play").bind "swipeleft", ->
            LastPart()

    $("#search").live "pagebeforeshow", (event) ->
        $("#search-form").submit ->
            $("#searchterm").blur()
            $.mobile.showPageLoadingMsg()
            $("#searchresult").empty()
            $.ajax
                type: "POST"
                contentType: "application/json; charset=utf-8"
                dataType: "json"
                url: "/Lyt/search.asmx/SearchFreetext"
                cache: false
                data: "{term:\"" + $("#searchterm").val() + "\"}"
                success: #fixme window.fileInterface.onSearchSuccess
                error: #fixme window.fileInterface.onSearchError
                complete: #fixme window.fileInterface.onSearchComplete

            false

        $("#searchterm").autocomplete
            source: (request, response) ->
                $.ajax
                    url: "/Lyt/search.asmx/SearchAutocomplete"
                    data: "{term:\"" + $("#searchterm").val() + "\"}"
                    dataType: "json"
                    type: "POST"
                    contentType: "application/json; charset=utf-8"
                    dataFilter: (data) ->
                        data

                    success: (data) ->
                        response $.map(data.d, (item) ->
                            value: item.keywords
                        )
                        $(".ui-autocomplete").css "visibility", "hidden"
                        list = $(".ui-autocomplete").find("li").each(->
                            $(this).removeAttr "class"
                            $(this).attr "class", "ui-icon-searchfield"
                            $(this).removeAttr "role"
                            $(this).html "<h3>" + $(this).find("a").text() + "</h3>"
                            $(this).attr "onclick", "javascript:$(\"#searchterm\").val('" + $(this).text() + "')"
                        )

                        $(list).html "<h3>Ingen forslag</h3>"  if list.length is 1 and $(list).find("h3:first").text().length is 0
                        $("#searchresult").html(list).listview "refresh"

                    error: (XMLHttpRequest, textStatus, errorThrown) ->
                        alert textStatus

            minLength: 2

        $("#searchterm").bind "autocompleteclose", (event, ui) ->
            $("#search-form").submit()

        $("#search li").live "click", ->
            $("#book-details-image").empty()
            $("#book-details-content").empty()
            $.ajax
                type: "POST"
                contentType: "application/json; charset=utf-8"
                dataType: "json"
                url: "/Lyt/search.asmx/GetItemById"
                cache: false
                data: "{itemid:\"" + $(this).attr("id") + "\"}"
                success: #fixme: window.fileInterface.onBookDetailsSuccess
                error: #fixme: window.fileInterface.onBookDetailsError

            false

    $("#bookshelf").live "pagebeforeshow", (event) ->
        $.mobile.hidePageLoadingMsg()

    $("#settings").live "pagebeforecreate", (event) ->
        initialize = true
        $("#textarea-example").css "font-size",  @settings.get('textSize') + "px"
        $("#textsize").find("input").val @settings.get('textSize')
        $("#textsize_2").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is  @settings.get('textSize')

        $("#text-types").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is  @settings.get('textType')

        $("#textarea-example").css "font-family", @settings.get('textType')
        $("#marking-color").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is  @settings.get('markingColor')

        $("#textarea-example").css "background", @settings.get('markingColor').substring(0,  @settings.get('markingColor').indexOf("-", 0))
        $("#textarea-example").css "color",  @settings.get('markingColor').substring(0,  @settings.get('markingColor').indexOf("-", 0) + 1)
        $("#textsize_2 input").change ->
            @settings.set('textSize', $(this).attr("value"))

            $("#textarea-example").css "font-size", @settings.get('textSize') + "px"
            $("#book-text-content").css "font-size", @settings.get('textSize') + "px"

        $("#text-types input").change ->
            @settings.set('textType', $(this).attr("value"))

            $("#textarea-example").css "font-family", @settings.get('textType')
            $("#book-text-content").css "font-family", @settings.get('textType')

        $("#marking-color input").change ->
            @settings.set('markingColor', $(this).attr("value"))

            $("#textarea-example").css "background", @settings.get('markingColor').substring(0, @settings.get('markingColor').indexOf("-", 0))
            $("#textarea-example").css "color", @settings.get('markingColor').substring(0, @settings.get('markingColor').indexOf("-", 0) + 1)
            $("#book-text-content").css "background", @settings.get('markingColor').substring(0, @settings.get('markingColor').indexOf("-", 0))
            $("#book-text-content").css "color", @settings.get('markingColor').substring(0, @settings.get('markingColor').indexOf("-", 0) + 1)

        $("#reading-context").click ->
            @settings.set('textPresentation', document.getElementById(@getAttribute("for")).getAttribute("value"))    


