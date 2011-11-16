# Application logic abstracted functions

LYT.app:
  
  next: "bookshelf"

  PlayNewBook: (id, title, author) ->
      $.mobile.showPageLoadingMsg()
      
      LYT.Pause()
      
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
      
      Play()

  eventSystemLoggedOn: (loggedOn, id) ->
      unless id is -1
          LYT.settings.set('username', id)

      if loggedOn
          $.mobile.changePage @next
          
      else
          $.mobile.hidePageLoadingMsg()
          $.mobile.changePage "#login"

  eventSystemNotLoggedIn: (where) ->
      @goto = where
      if @settings.username isnt "" and @settings.password isnt ""
          console.log "GUI: Event system not logged in, logger på i baggrunden"  if console
          LYT.protocol.LogOn LYT.settings.get('username'), LYT.settings.get('password')
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

  showIndex: ->
      $.mobile.changePage "#book_index"

  playCurrent: ->
      if isPlayerAlive()
        $.mobile.changePage "#book-play"
      else
        @PlayNewBook @settings.currentBook, @settings.currentTitle, @settings.currentAuthor

  gotoPage: ->
      console.log "GUI: gotoPage - " + @goto  if console
      switch @goto
          when "bookshelf"
              window.fileInterface.GetBookShelf()
              @goto = ""
          else
              window.fileInterface.GetBookShelf()  if $(".ui-page-active").attr("id") is "login"

  logUserOff: ->
      LYT.settings.set('username', "")
      LYT.settings.set('password', "")
      LYT.protocol.LogOff()
      