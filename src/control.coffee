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
    params = LYT.router.getParams(match[1])
    content = $(page).children( ":jqmData(role=content)" )
    
    if params.book
      $.mobile.showPageLoadingMsg()
      LYT.Book.load(params.book)                            
        .done (book) ->
        
          LYT.render.bookIndex(book, content)
          $.mobile.hidePageLoadingMsg()
        
          #jQuery("#book-index ol l").each ->
          #  #log.message jQuery(@).attr('href')
          #  #attr = jQuery(@).attr('href') + '?book=15000'
          #  #jQuery(@).attr('href', attr)
  
  bookPlayer: (type, match, ui, page) ->
    $.mobile.showPageLoadingMsg()
    
    params = LYT.router.getParams(match[1])
    
    #fixme: next line should probably update the href preserving current parameters in hash instead of replacing
    header = $(page).children( ":jqmData(role=header)") 
    $('#book-index-button').attr 'href', """#book-index?book=#{params.book}"""
    
    section = params.section or 0
    offset = params.offset or 0
    
      
    #content = $(page).children( ":jqmData(role=content)" )
        
    LYT.Book.load(params.book)                            
      .done (book) ->
        
        #log.message book.nccDocument.structure
        
        #fixme: lookup section by its ID so we send the right one the the renderer.
        #section = book.nccDocument.structure[1]

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
    content = $(page).children( ":jqmData(role=content)" )
    
    LYT.search.attachAutocomplete $('#searchterm')  
    # TODO: Shouldn't this only be bound once? Or does jQuery take care of that?
    $(LYT.search).bind 'autocomplete', (event) ->
      log.message "Autocomplete suggestions: #{event.results}"
    
    #log.message type, match, ui, page
       
    if params.term  # this allows for bookmarkable search terms
      LYT.search.full(params.term)
        .done (results) ->
          LYT.render.searchResults(results, content)
          $.mobile.hidePageLoadingMsg()
    
    $("#search-form").submit (event) ->
      log.message 'you searched'      
      $('#searchterm').blur()
      $.mobile.showPageLoadingMsg()
      
      $.mobile.changePage "#search?term=#{$('#searchterm').val()}",
        allowSamePageTransition: true
      
      event.preventDefault()
      event.stopImmediatePropagation()
      
      #$.mobile.changePage "#search",
      #  allowSamePageTransition: true
      #  type: "get"
      #  data: $("form#search-form").serialize()
      
      #$.mobile.changePage("#{page}?term=#{$('#searchterm').val()}")
      
      #LYT.search.full()
      #  .done (results) ->
      #    LYT.render.searchResults(results, content)
      #    $.mobile.hidePageLoadingMsg()
          

  
  settings: (type, match, ui, page) ->      
    style = LYT.settings.get('textStyle')
    
    $("#style-settings").find("input").each ->
      name = $(this).attr 'name'
      val = $(this).val()
      
      switch name
        when 'font-size', 'font-family'
          if val is style[name]
            $(this).attr("checked", true).checkboxradio("refresh");
        when 'marking-color'
          colors = val.split(';')
          if style['background-color'] is colors[0] and style['color'] is colors[1]
            $(this).attr("checked", true).checkboxradio("refresh");
            
    $("#style-settings input").change (event) ->     
      target = $(event.target)
      name = target.attr 'name'
      val = target.val()
      
      switch name
        when 'font-size', 'font-family'
          style[name] = val
        when 'marking-color'
          colors = val.split(';')
          style['background-color'] = colors[0]
          style['color'] = colors[1]
      
      LYT.settings.set('textStyle', style)
      LYT.render.setStyle()
  
  profile: (type, match, ui, page) ->
    $("#log-off").click (event) ->
      LYT.service.logOff()
      
      