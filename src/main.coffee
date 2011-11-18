$(document).bind "mobileinit", ->
  
    LYT.player.setup()
    #Todo:implement permanent links to books and chapters - http://jquerymobile.com/test/docs/pages/page-dynamic.html
    
    $(document).bind "pagebeforechange", (e, data) ->
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
        LYT.app.next = "bookshelf"
        
        $.mobile.showPageLoadingMsg()
        $("#password").blur()
        
        event.preventDefault()
        event.stopPropagation()
    
        LYT.service.LogOn $("#username").val(), $("#password").val()
        
    $("#book_index").live "pagebeforeshow", (event) ->
      $("#book_index_content").trigger "create"
      $("li[xhref]").bind "click", (event) ->
             $.mobile.showPageLoadingMsg()
             
             if ($(window).width() - event.pageX > 40) or (typeof $(this).find("a").attr("href") is "undefined") # submenu handling
                if $(this).find("a").attr("href")
                    event.preventDefault()
                    event.stopPropagation()
                    event.stopImmediatePropagation()                   
                    
                    book = new LYT.Book 1                                
                    book.done (book) ->
                      LYT.player.loadBook(book)
                      
                      $.mobile.changePage "#book-play"
                    book.fail () ->
                      #todo:error                            
                    
                else
                    event.stopImmediatePropagation()
                    $.mobile.changePage $(this).find("a").attr("href")

    $("#book-play").live "pagebeforeshow", (event) ->
            
        LYT.gui.covercache_one $("#book-middle-menu")
        $("#book-text-content").css "background", LYT.settings.get('markingColor').substring( LYT.settings.get('markingColor').indexOf("-", 0))
        $("#book-text-content").css "color", LYT.settings.get('markingColor').substring( LYT.settings.get('markingColor').indexOf("-", 0) + 1)
        $("#book-text-content").css "font-size",  LYT.settings.get('textSize') + "px"
        $("#book-text-content").css "font-family",  LYT.settings.get('textType')
        $("#bookshelf [data-role=header]").trigger "create"

        $("#book-play").bind "swiperight", ->
            LYT.player.nextPart()

        $("#book-play").bind "swipeleft", ->
            LYT.player.previousPart()

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
    