# Application logic
#
LYT.control =
    
  login: (eventType, matchObj, ui, page) ->
    $("#login-form").submit (event) ->

      $.mobile.showPageLoadingMsg()
      $("#password").blur()

      LYT.service.logOn($("#username").val(), $("#password").val())
        .done ->
          $.mobile.changePage "#bookshelf"

        .fail ->
          log.message "log on failure"

      event.preventDefault()
      event.stopPropagation()
  
    
  bookshelf: (eventType, matchObj, ui, page) ->
    $.mobile.showPageLoadingMsg()
    $content = page.children(":jqmData(role=content)")
    
    LYT.bookshelf.load()
      .done (books) ->
        LYT.render.bookshelf(books, $content)
        
        ###
        $content.find('a').click ->
          alert 'We got some dixie chicks for ya while you wait for your book!'
          if LYT.player.ready
            LYT.player.silentPlay()
          else
            LYT.player.el.bind $.jPlayer.event.ready, (event) ->
              LYT.player.silentPlay()
        ###
        
        $.mobile.hidePageLoadingMsg()
      .fail (error, msg) ->
        log.message "failed with error #{error} and msg #{msg}"
  
  
  bookDetails: (eventType, matchObj, ui, page) ->
    $.mobile.showPageLoadingMsg()
    #todo: clear data from earlier book
    bookId = urlObj.hash.replace(/.*book=/, "")
    
    pageSelector = urlObj.hash.replace(/\?.*$/, "")
    $page = $(pageSelector)
    $header = $page.children( ":jqmData(role=header)" )
    $content = $page.children( ":jqmData(role=content)" )

    book = new LYT.Book(bookId)                                
      .done (book) ->
        currentBook = book
        metadata = book.nccDocument.getMetadata()
        #log.message metadata
        
        LYT.gui.renderBookDetails(book, $content)
        
        $content.find("#play-button").click (e) =>
          e.preventDefault()
          $.mobile.changePage("#book-play?book=" + bookId)

        LYT.gui.covercacheOne $content.find("figure"), bookId
        
        #$page.page()
        
        options.dataUrl = urlObj.href
        $.mobile.hidePageLoadingMsg()     
        $.mobile.changePage $page, options         

      .fail (error, msg) ->
        log.message "failed with error #{error} and msg #{msg}"
  
  bookIndex: (eventType, matchObj, ui, page) ->
    $.mobile.showPageLoadingMsg()
        
    bookId = getParam('book', urlObj.hash)
    
    $header = page.children( ":jqmData(role=header)" )
    $content = page.children( ":jqmData(role=content)" )
    
    #unless bookId?
    
    book = new LYT.Book(bookId)                            
      .done (book) ->
        currentBook = book
        LYT.render.bookIndex(book, $content)
        
        $page.page()
        
        options.dataUrl = urlObj.href
        $.mobile.hidePageLoadingMsg()
        $.mobile.changePage $page, options
        
        #$("#book-index ol l").each ->
        #  #log.message $(@).attr('href')
        #  #attr = $(@).attr('href') + '?book=15000'
        #  #$(@).attr('href', attr)
  
  bookPlayer: (eventType, matchObj, ui, page) ->
    $.mobile.showPageLoadingMsg() 
    
    bookId = getParam('book', urlObj.hash)
    sectionNumber = getParam('section', urlObj.hash) or 0  
    offset = getParam('offset', urlObj.hash) or 0
    
    $header = page.children( ":jqmData(role=header)" )
    $content = page.children( ":jqmData(role=content)" )
    
    book = new LYT.Book(bookId)                            
      .done (book) ->
        
        metadata = book.nccDocument.getMetadata()
        book.nccDocument.structure 
        
        section = book.nccDocument.structure[sectionNumber]
        
        LYT.render.bookPlayer(book, section, $page)
        
        if LYT.player.ready
          LYT.player.loadSection(book, section.id, offset)
        else
          LYT.player.el.bind $.jPlayer.event.ready, (event) ->
            LYT.player.loadSection(book, section.id, offset)
                                
        ###
        $("#book-play").bind "swiperight", ->
            LYT.player.nextSection()

        $("#book-play").bind "swipeleft", ->
            LYT.player.previousSection()
        ###
                
        #$page.page()
        options.dataUrl = urlObj.href
        $.mobile.hidePageLoadingMsg()
        #alert "App: changing the page"
        $.mobile.changePage $page, options
        
      .fail () ->
        log.message "failed"
        
###
LYT.app = #deprecated split into control object and the stuff that don't fit should go in utils, locally used utils can just be outside of the object
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
###     