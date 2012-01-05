# This module Controller
LYT.control =    
  login: (type, match, ui, page, event) ->
    $("#login-form").submit (event) ->
      
      LYT.loader.set("Logger ind", "login")
      $("#password").blur()
      
      LYT.service.logOn($("#username").val(), $("#password").val())
        .done ->
          $.mobile.changePage "#bookshelf"
        
        .fail ->
          log.message "log on failure"
        
      event.preventDefault()
      event.stopPropagation()
    
  
  bookshelf: (type, match, ui, page, event) ->
    if type is 'pageshow'
      content = $(page).children(":jqmData(role=content)")
    
      load = (page = 1) ->
        LYT.loader.set("Henter boghylde", "get_bookshelf")    
        LYT.bookshelf.load(page)
          .done (books) ->
            LYT.render.bookshelf(books, content, page)
            
            $("#more-bookshelf-entries").unbind "click"
            if books.nextPage
              $("#more-bookshelf-entries").click (event) ->
                load books.nextPage
                event.preventDefault()
                event.stopImmediatePropagation()
              $("#more-bookshelf-entries").show()
            else
              $("#more-bookshelf-entries").hide()
            
            LYT.loader.close("get_bookshelf")
          
          .fail (error, msg) ->
            log.message "failed with error #{error} and msg #{msg}"
        
      load()
  
  bookDetails: (type, match, ui, page, event) ->
    if type is 'pageshow'
      LYT.loader.set("Henter bog", "get_details")
      
      params = LYT.router.getParams(match[1])
      content = $(page).children( ":jqmData(role=content)" )
        
      LYT.Book.getDetails(params.book)
        .done (details) ->
          LYT.render.bookDetails(details, content)
          
          content.find("#play-button").click (event) ->
            $.mobile.changePage("#book-play?book=#{params.book}")
            event.preventDefault()
            event.stopImmediatePropagation()
          
          content.find("#add-to-bookshelf-button").one "click", (event) ->
            LYT.loader.set("Tilføjer bog til boghylde", "add_to_bookshelf")
            # TODO: This is far from perfect: The loading-thing might
            # blink on and off due to the changePage, there's no way
            # of knowing if something's already on the shelf, etc.
            LYT.bookshelf.add(params.book)
              .done ->
                $.mobile.changePage("#bookshelf")
              .always ->
                LYT.loader.close("add_to_bookshelf")
            event.preventDefault()
            event.stopImmediatePropagation()
          
          LYT.loader.close("get_details")
        
        .fail (error, msg) ->
          log.message "failed with error #{error} and msg #{msg}"
  
  bookIndex: (type, match, ui, page, event) ->
    if type is 'pageshow'
      
      return unless match[1] # Hack to avoid eternal pageloading on jqm subpages
      
      LYT.loader.set("Henter indeks", "get_index")
      
      params = LYT.router.getParams(match[1])
      content = $(page).children( ":jqmData(role=content)" )
    
      if params.book
        LYT.Book.load(params.book)
          .done (book) ->
          
            LYT.render.bookIndex(book, content)
            LYT.loader.close("get_index")
  
  bookPlayer: (type, match, ui, page, event) ->
    if type is 'pageshow'
      LYT.loader.set("Henter bog", "player")
      params = LYT.router.getParams(match[1])
  
      header = $(page).children( ":jqmData(role=header)")
      $('#book-index-button').attr 'href', """#book-index?book=#{params.book}"""
  
      section = params.section or null
      offset = params.offset or 0
      
      LYT.Book.load(params.book)
        .done (book) ->        
          LYT.render.bookPlayer book, $(page)
          if not section and offset is 0 and book.lastmark?
            log.message "Found lastmark. Resuming play at section #{book.lastmark.section} and offset #{book.lastmark.offset}"
            section = book.lastmark.section
            offset  = book.lastmark.offset
            # TODO: Set correct URL
            # Maybe just do it this way: $.mobile.changePage("#book-play?book=#{book.id}&section=#{section.id}&offset=#{offset}") ?
            
          LYT.player.load book, section, offset
          ###
          $("#book-play").bind "swiperight", ->
              LYT.player.nextSection()
      
          $("#book-play").bind "swipeleft", ->
              LYT.player.previousSection()
          ###
      
        .fail () ->
          log.error "Control: Failed to load book ID #{params.book}"
  
  search: (type, match, ui, page, event) ->
    if type is 'pageshow'
      loadResults = (term, page = 1) ->
        LYT.loader.set LYT.i18n("Searching"), "search"
        LYT.search.full(term, page)
          .done (results) ->
            $("#more-search-results").unbind "click"
            $("#more-search-results").click (event) ->
              loadResults term, results.nextPage if results.nextPage
              event.preventDefault()
              event.stopImmediatePropagation()
            
            LYT.render.searchResults(results, content)
            LYT.loader.close "search"
      
      if match?[1]
        params = LYT.router.getParams match[1]
      else
        params = {}
      
      params.term = jQuery.trim(decodeURI(params.term or "")) or null
      
      content = $(page).children( ":jqmData(role=content)" )
      
      LYT.search.attachAutocomplete $('#searchterm')
      $("#searchterm").bind "autocompleteselect", (event, ui) ->
        loadResults ui.item.value
        $.mobile.changePage "#search?term=#{encodeURI ui.item.value}" , transition: "none"
      
      # this allows for bookmarkable search terms
      if params.term and $('#searchterm').val() isnt params.term
        $('#searchterm').val params.term
        loadResults params.term
      
      $("#search-form").submit (event) ->
        $('#searchterm').blur()
        
        term = encodeURI $('#searchterm').val()
        loadResults $('#searchterm').val()
        $.mobile.changePage "#search?term=#{term}" , transition: "none"
        
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
      
  
  
  settings: (type, match, ui, page, event) ->
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
  
  profile: (type, match, ui, page, event) ->
    $("#log-off").click (event) ->
      LYT.service.logOff()
    
  
