$(document).bind "mobileinit", ->
  
  #Todo:implement permanent links to books and chapters - http://jquerymobile.com/test/docs/pages/page-dynamic.html
  
  
  playBook = (book, section, offset) ->
     #log.message book.nccDocument.structure
     LYT.player.loadBook(book, section)
     
  
  renderBookPlay = (urlObj, options) -> 
    
    bookId = urlObj.hash.replace(/.*book=/, "")
    #section = urlObj.hash.replace(/.*section=/, "")
    offset = urlObj.hash.replace(/.*offset=/, "")
    
    pageSelector = urlObj.hash.replace(/\?.*$/, "")
    
    $page = $(pageSelector)
    $header = $page.children( ":jqmData(role=header)" )
    $content = $page.children( ":jqmData(role=content)" )
    
    book = new LYT.Book(bookId)                                
      .done (book) ->
        
        metadata = book.nccDocument.getMetadata() 
        
        $page.find("#title").text metadata.title.content        
        $page.find("#author").text toSentence(metadata.creator.map((creator) ->
          creator.content
        ))
        
        log.message book.nccDocument.structure
        section = book.nccDocument.structure[4]
        $page.find("#book_chapter").text section.title
        
        if not LYT.player.ready
          LYT.player.setup()  
          LYT.player.el.bind jQuery.jPlayer.event.ready, (event) =>
             playBook(book, section)
        else
          playBook(book, section)
              
                
        $page.page()
        options.dataUrl = urlObj.href        
        $.mobile.changePage $page, options
        
      .fail () ->
        log.message "get book failure"
  
  renderBookDetails = (urlObj, options) ->
    $.mobile.showPageLoadingMsg()
    
    bookId = urlObj.hash.replace(/.*book=/, "")
    
    pageSelector = urlObj.hash.replace(/\?.*$/, "")
    $page = $(pageSelector)
    $header = $page.children( ":jqmData(role=header)" )
    $content = $page.children( ":jqmData(role=content)" )
    
    log.message "Rendering book details for book with id " + bookId

    book = new LYT.Book(bookId)                                
      .done (book) ->
        metadata = book.nccDocument.getMetadata()
        
        $content.find("#title").text metadata.title.content        
        $content.find("#author").text toSentence(metadata.creator.map((creator) ->
          creator.content
        ))
        
        $content.find("#narrator").text toSentence(metadata.narrator.map((narrator) ->
          narrator.content
        ))       
        
        $content.find("#totaltime").text metadata.totalTime.content
        
        $content.find("#play-button").click (e) =>
          e.preventDefault()
          $.mobile.changePage("#book-play?book=" + bookId)
        
        LYT.gui.covercacheOne $content.find("figure"), bookId
        
        log.message metadata   
        
        $page.page()
        
        options.dataUrl = urlObj.href        
        $.mobile.changePage $page, options         

      .fail () ->
        log.message "get book failure"

     
    
  $(document).bind "pagebeforechange", (e, data) ->
      # Intercept and parse urls with a query string
      if typeof data.toPage is "string"
        u = $.mobile.path.parseUrl(data.toPage)
        
        if u.hash.search(/^#book-details/) isnt -1
          renderBookDetails u, data.options
          e.preventDefault()
        else if u.hash.search(/^#book-play/) isnt -1
          renderBookPlay u, data.options
          e.preventDefault()
        else if u.hash.search(/^#book-index/) isnt -1
          renderBookIndex u, data.options
          e.preventDefault()
      
  $("#login").live "pagebeforeshow", (event) ->
      $("#login-form").submit (event) ->
        
        $.mobile.showPageLoadingMsg()
        $("#password").blur()
        
        LYT.service.logOn($("#username").val(), $("#password").val())
          .done ->
            $.mobile.changePage "#book-details?book=15000"
            
          .fail ->
            log.message "log on failure"
          
        event.preventDefault()
        event.stopPropagation()
  
  
  ###      
  $("#book_index").live "pagebeforeshow", (event) ->
      $("#book_index_content").trigger "create"
      $("li[xhref]").bind "click", (event) ->
             $.mobile.showPageLoadingMsg()
             
             if ($(window).width() - event.pageX > 40) or (typeof $(this).find("a").attr("href") is "undefined") # submenu handling
                if $(this).find("a").attr("href")
                    event.preventDefault()
                    event.stopPropagation()
                    event.stopImmediatePropagation()                   
                                                
                    
                else
                    event.stopImmediatePropagation()
                    $.mobile.changePage $(this).find("a").attr("href")###

  ###$("#book-play").live "pagebeforeshow", (event) ->
            
        LYT.gui.covercache_one $("#book-middle-menu")
        $("#book-text-content").css "background", LYT.settings.get('markingColor').substring( LYT.settings.get('markingColor').indexOf("-", 0))
        $("#book-text-content").css "color", LYT.settings.get('markingColor').substring( LYT.settings.get('markingColor').indexOf("-", 0) + 1)
        $("#book-text-content").css "font-size",  LYT.settings.get('textSize') + "px"
        $("#book-text-content").css "font-family",  LYT.settings.get('textType')
        $("#bookshelf [data-role=header]").trigger "create"

        $("#book-play").bind "swiperight", ->
            LYT.player.nextPart()

        $("#book-play").bind "swipeleft", ->
            LYT.player.previousPart()###

  $("#bookshelf").live "pagebeforeshow", (event) ->
        $.mobile.hidePageLoadingMsg()

  $("#settings").live "pagebeforecreate", (event) ->
        initialize = true
        $("#textarea-example").css "font-size",  LYT.settings.get('textSize') + "px"
        $("#textsize").find("input").val LYT.settings.get('textSize')
        $("#textsize_2").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('textSize')

        $("#text-types").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('textType')

        $("#textarea-example").css "font-family", LYT.settings.get('textType')
        $("#marking-color").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('markingColor')

        $("#textarea-example").css "background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
        $("#textarea-example").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
        $("#textsize_2 input").change ->
            LYT.settings.set('textSize', $(this).attr("value"))

            $("#textarea-example").css "font-size", LYT.settings.get('textSize') + "px"
            $("#book-text-content").css "font-size", LYT.settings.get('textSize') + "px"

        $("#text-types input").change ->
            LYT.settings.set('textType', $(this).attr("value"))

            $("#textarea-example").css "font-family", LYT.settings.get('textType')
            $("#book-text-content").css "font-family", LYT.settings.get('textType')

        $("#marking-color input").change ->
            LYT.settings.set('markingColor', $(this).attr("value"))

            $("#textarea-example").css "background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#textarea-example").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
            $("#book-text-content").css "background", vsettings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#book-text-content").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
   
    
  $("[data-role=page]").live "pageshow", (event, ui) ->
        _gaq.push [ "_trackPageview", event.target.id ]      
    