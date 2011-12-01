# This module Controller
LYT.control =
    
  login: (type, match, ui, page) ->
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
  
    
  bookshelf: (type, match, ui, page) ->
    $.mobile.showPageLoadingMsg()
    
    content = $(page).children(":jqmData(role=content)")
    
    LYT.bookshelf.load()
      .done (books) ->
        log.message books
        LYT.render.bookshelf(books, content)
        
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
  
  
  bookDetails: (type, match, ui, page) ->
    $.mobile.showPageLoadingMsg()
    params = LYT.router.getParams(match[1])
    
    $.mobile.showPageLoadingMsg()   
    content = $(page).children( ":jqmData(role=content)" )    
    
    # todo validate query string
    
    LYT.Book.load(params.book)                                
      .done (book) ->
        log.message book
        
        LYT.render.bookDetails(book, content)
        
        content.find("#play-button").click (e) =>
          e.preventDefault()
          $.mobile.changePage("#book-play?book=" + book.id)

        #LYT.render.covercacheOne content.find("figure"), bookId
        
        #$page.page()
        $.mobile.hidePageLoadingMsg()     
        #$.mobile.changePage page, options         

      .fail (error, msg) ->
        log.message "failed with error #{error} and msg #{msg}"
  
  bookIndex: (type, match, ui, page) ->
    $.mobile.showPageLoadingMsg()
    params = LYT.router.getParams(match[1])
     
    content = $(page).children( ":jqmData(role=content)" )
    
    LYT.Book.load(params.book)                            
      .done (book) ->
        
        LYT.render.bookIndex(book, content)
        jQuery.mobile.hidePageLoadingMsg()
        
        #jQuery("#book-index ol l").each ->
        #  #log.message jQuery(@).attr('href')
        #  #attr = jQuery(@).attr('href') + '?book=15000'
        #  #jQuery(@).attr('href', attr)
  
  bookPlayer: (type, match, ui, page) ->
    jQuery.mobile.showPageLoadingMsg()
    
    params = LYT.router.getParams(match[1]) 
    section = params.section or 0
    offset = params.offset or 0
    
    header = $(page).children( ":jqmData(role=header)")   
    #content = $(page).children( ":jqmData(role=content)" )
        
    LYT.Book.load(params.book)                            
      .done (book) ->
        
        #log.message book.nccDocument.structure
        
        #fixme: lookup section by its ID so we send the right one the the renderer.
        #section = book.nccDocument.structure[1]
        
        #fixme: next line should probably update the href preserving current parameters in hash instead of replacing
        header.find('#book-index-button').attr 'href', """#book-index?book=#{book.id}"""
        
        LYT.render.bookPlayer(book, $(page))
        
        if LYT.player.ready
          LYT.player.loadSection(book, section, offset)
        else
          LYT.player.el.bind $.jPlayer.event.ready, (event) ->
            LYT.player.loadSection(book, section, offset)
                                
        ###
        $("#book-play").bind "swiperight", ->
            LYT.player.nextSection()
            
        $("#book-play").bind "swipeleft", ->
            LYT.player.previousSection()
        ###
                
        $.mobile.hidePageLoadingMsg()
        
      .fail () ->
        log.message "failed"
  
  search: (type, match, ui, page) ->
    params = LYT.router.getParams(match[1])
    
    if params.term
      
      LYT.search.full(params.term)
        .done (result) ->
          log.message(result)
    
    
    
          
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