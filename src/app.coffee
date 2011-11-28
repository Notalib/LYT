# Application logic

LYT.app =
  currentBook: null
  next: "bookshelf"
  
  bookshelf: ->
    $.mobile.showPageLoadingMsg()
    $page = $("#bookshelf")
    $content = $page.children(":jqmData(role=content)")
    
    LYT.bookshelf.load()
      .done (books) ->
        LYT.gui.renderBookshelf(books, $content)
        
        $content.find('a').click ->
          alert 'We got some dixie chicks for ya while you wait for your book!'
          if LYT.player.ready
            LYT.player.silentPlay()
          else
            LYT.player.el.bind $.jPlayer.event.ready, (event) ->
              LYT.player.silentPlay()
        
        $.mobile.hidePageLoadingMsg()
      .fail (error, msg) ->
        log.message "failed with error #{error} and msg #{msg}"
  
  bookDetails: (urlObj, options) ->
    $.mobile.showPageLoadingMsg()
    #todo: clear data from earlier book
    bookId = urlObj.hash.replace(/.*book=/, "")
    
    pageSelector = urlObj.hash.replace(/\?.*$/, "")
    $page = $(pageSelector)
    $header = $page.children( ":jqmData(role=header)" )
    $content = $page.children( ":jqmData(role=content)" )

    book = new LYT.Book(bookId)                                
      .done (book) ->
        metadata = book.nccDocument.getMetadata()
        #log.message metadata
        
        LYT.gui.renderBookDetails(metadata, $content)
        
        $content.find("#play-button").click (e) =>
          e.preventDefault()
          $.mobile.changePage("#book-play?book=" + bookId)

        LYT.gui.covercacheOne $content.find("figure"), bookId
        
        $page.page()
        
        options.dataUrl = urlObj.href
        $.mobile.hidePageLoadingMsg()     
        $.mobile.changePage $page, options         

      .fail (error, msg) ->
        log.message "failed with error #{error} and msg #{msg}"
  
  bookPlayer: (urlObj, options) ->
    $.mobile.showPageLoadingMsg() 
    pageSelector = urlObj.hash.replace(/\?.*$/, "")
    
    bookId = getParam('book', urlObj.hash)
    sectionNumber = getParam('section', urlObj.hash) or 0  
    offset = getParam('offset', urlObj.hash) or 0
    
    $page = $(pageSelector)
    $header = $page.children( ":jqmData(role=header)" )
    $content = $page.children( ":jqmData(role=content)" )
    
    book = new LYT.Book(bookId)                            
      .done (book) ->
        
        metadata = book.nccDocument.getMetadata()
        book.nccDocument.structure 
        
        alert "App: got book"
        section = book.nccDocument.structure[sectionNumber]
        
        alert "App: about to render book"
        LYT.gui.renderBookPlayer(metadata, section, $page)
        alert "App: finished rendering book"
        
        if LYT.player.ready
          alert "App: player was ready loading secttion"
          LYT.player.loadSection(book, section.id, offset)
        else
          LYT.player.el.bind $.jPlayer.event.ready, (event) ->
            alert "App: player was not ready waiting for it"
            LYT.player.loadSection(book, section.id, offset)
                                
        ###
        $("#book-play").bind "swiperight", ->
            LYT.player.nextPart()

        $("#book-play").bind "swipeleft", ->
            LYT.player.previousPart()
        ###
                
        #$page.page()
        options.dataUrl = urlObj.href
        $.mobile.hidePageLoadingMsg()
        alert "App: changing the page"
        $.mobile.changePage $page, options
        
      .fail (error, msg) ->
        log.message "failed with error #{error} and msg #{msg}"

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
      