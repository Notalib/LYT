# Application logic abstracted functions

LYT.app =
  currentBook: null
  next: "bookshelf"

  eventSystemLoggedOn: (loggedOn, id) ->
      unless id is -1
          LYT.settings.set('username', id)

      if loggedOn
          $.mobile.changePage @next
          
      else
          $.mobile.hidePageLoadingMsg()
          $.mobile.changePage "#login"

  eventSystemNotLoggedIn: (where) ->
      @next = where
      if @settings.username isnt "" and @settings.password isnt ""
          log "GUI: Event system not logged in, logger på i baggrunden"  if console
          LYT.protocol.LogOn LYT.settings.get('username'), LYT.settings.get('password')
      else
          $.mobile.changePage "#login"

  eventSystemGotBookShelf: (bookShelf) =>
      @next = ""
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

  logUserOff: ->
      LYT.settings.set('username', "")
      LYT.settings.set('password', "")
      LYT.protocol.LogOff()
      