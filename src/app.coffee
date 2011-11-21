# Application logic

#todo: create a listener for SERVICE_MUST_LOGON_ERROR that redirects to #login and sets next to requested page 

LYT.app =
  currentBook: null
  next: "bookshelf"
  
  bookshelf: ->
    $page = $("#bookshelf")
    $content = $page.children(":jqmData(role=content)")
    
    LYT.bookshelf.load()
      .done (books) ->
        LYT.gui.renderBookshelf(books, $content)
        
        $content.find('a').click ->
          log.message 'click'
          if LYT.player.ready
            alert 'dixie chicks'
            #LYT.player.play()
            LYT.player.el.jPlayer('play')
            #LYT.player.pause()
        
        $.mobile.hidePageLoadingMsg()
      .fail (error, msg) ->
        if error is SERVICE_MUST_LOGON_ERROR
          $.mobile.changePage("#login")
  
  bookDetails: (urlObj, options) ->
    #todo: clear data from earlier book
    bookId = urlObj.hash.replace(/.*book=/, "")
    
    pageSelector = urlObj.hash.replace(/\?.*$/, "")
    $page = $(pageSelector)
    $header = $page.children( ":jqmData(role=header)" )
    $content = $page.children( ":jqmData(role=content)" )
    
    log.message "Rendering book details for book with id " + bookId

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
        if error is SERVICE_MUST_LOGON_ERROR
          $.mobile.changePage("#login")
  
  bookPlayer: (urlObj, options) -> 
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
        
        log.message book.nccDocument.structure
        section = book.nccDocument.structure[sectionNumber]
        
        LYT.gui.renderBookPlayer(metadata, section, $page)
        
        if not LYT.player.ready
          LYT.player.setup()  
          LYT.player.el.bind jQuery.jPlayer.event.ready, (event) =>
             LYT.player.loadBook(book, section, offset)
        else
          LYT.player.loadBook(book, section, offset)
                          
        ###
        $("#book-play").bind "swiperight", ->
            LYT.player.nextPart()

        $("#book-play").bind "swipeleft", ->
            LYT.player.previousPart()
        ###
                
        $page.page()
        options.dataUrl = urlObj.href
        $.mobile.hidePageLoadingMsg()
        $.mobile.changePage $page, options        
        
      .fail (error, msg) ->
        if error is SERVICE_MUST_LOGON_ERROR
          $.mobile.changePage("#login")

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
      