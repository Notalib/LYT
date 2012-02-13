# Requires `/common`  
# Requires `/support/lyt/loader`  
# Requires `/models/book/book`  
# Requires `/models/member/bookshelf`  
# Requires `/models/member/settings`  
# Requires `/models/service/service`  
# Requires `/models/service/catalog`  
# Requires `/models/service/lists`  
# Requires `/view/render`  
# Requires `player`  

# -------------------

# This is the main controller for the app. It handles most of the business-logic
# involved in displaying the requested pages

LYT.control =    
  login: (type, match, ui, page, event) ->
    $("#login-form").submit (event) ->
      
      $("#password").blur()
      
      process = LYT.service.logOn($("#username").val(), $("#password").val())
        .done ->
          # log.message ui
          
          unless LYT.var.next
            LYT.var.next = "#bookshelf"
             
          $.mobile.changePage LYT.var.next
        
        .fail ->
          log.message "log on failure"
      
      LYT.loader.register "Logging in", process
      
      event.preventDefault()
      event.stopPropagation()
    
  
  bookshelf: (type, match, ui, page, event) ->
    if type is 'pageshow'
      content = $(page).children(":jqmData(role=content)")
    
      load = (page = 1) ->
        process = LYT.bookshelf.load(page)
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
          
          .fail (error, msg) ->
            log.message "failed with error #{error} and msg #{msg}"
        
        LYT.loader.register "Loading bookshelf", process
        
      load()
  
  bookDetails: (type, match, ui, page, event) ->
    if type is 'pageshow'
      params = LYT.router.getParams(match[1])
      content = $(page).children( ":jqmData(role=content)" )
        
      process = LYT.catalog.getDetails(params.book)
        .done (details) ->
          LYT.render.bookDetails(details, content)
          
          content.find("#add-to-bookshelf-button").one "click", (event) ->
            # TODO: This is far from perfect: There's no way
            # of knowing if something's already on the shelf
            LYT.loader.register "Adding book to bookshelf", LYT.bookshelf.add(params.book).done( -> $.mobile.changePage "#bookshelf" )
            
            event.preventDefault()
            event.stopImmediatePropagation()
        
        .fail (error, msg) ->
          log.message "failed with error #{error} and msg #{msg}"
      
      LYT.loader.register "Loading book", process
  
  bookIndex: (type, match, ui, page, event) ->
    if type is 'pageshow'
      return unless match[1] # Hack to avoid eternal pageloading on jqm subpages
      
      params = LYT.router.getParams(match[1])
      content = $(page).children( ":jqmData(role=content)" )
      
      if params.book
        process = LYT.Book.load(params.book).done (book) ->
          LYT.render.bookIndex(book, content)
        
        LYT.loader.register "Loading index", process
  
  bookPlayer: (type, match, ui, page, event) ->
    if type is 'pageshow'
      
      params = LYT.router.getParams(match[1])
      section = params.section or null
      offset = params.offset or 0
      
      # if book and section is the same as what is currently playing don't do anything new here
      
      if LYT.player.book?    
        if LYT.player.book.id is params.book
          # this book is already playing maybe we should not change anything
          if not section? or not LYT.player.section?
            # section is either not defined in url or in book 
            return
          else if section is LYT.player.section.id
            # section is the same as already playing don't chaneg anything
            return
          else
           # this is a new section - load it
        
      header = $(page).children( ":jqmData(role=header)")
      $('#book-index-button').attr 'href', """#book-index?book=#{params.book}"""    
      
      process = LYT.Book.load(params.book)
        .done (book) ->        
          LYT.render.bookPlayer book, $(page)
          if not section and offset is 0 and book.lastmark?
            log.message "Found lastmark. Resuming play at section #{book.lastmark.section} and offset #{book.lastmark.offset}"
            section = book.lastmark.section
            offset  = book.lastmark.offset
            
          LYT.player.load book, section, offset, false
          ###
          $("#book-play").bind "swiperight", ->
              LYT.player.nextSection()
          
          $("#book-play").bind "swipeleft", ->
              LYT.player.previousSection()
          ###
        
        .fail () ->
          log.error "Control: Failed to load book ID #{params.book}"
          
          #if LYT.session.getCredentials()?
          # Hack to fix books not loading when being redirected directly from login page
          if $.mobile.prevPage[0].id is 'login'
            window.location.reload()
          else
            $(this).simpledialog({
              'mode' : 'bool',
              'prompt' : 'Hentnings fejl!',
              'subTitle' : 'Kunne ikke hente bogen #{params.book}'
              'useModal': true,
              'buttons' : {
                'OK':{
                }
                icon: "delete",
                theme: "c"
              }
            })

            
      
      LYT.loader.register "Loading book", process
  
  search: (type, match, ui, page, event) ->
    if type is 'pageshow'
      
      handleResults = (process) ->
        LYT.loader.register "Searching", process
        process.done (results) ->
          $("#more-search-results").unbind "click"
          $("#more-search-results").click (event) ->
            handleResults results.loadNextPage() if results.loadNextPage?
            event.preventDefault()
            event.stopImmediatePropagation()
          
          LYT.render.searchResults results, content
      
      
      if match?[1]
        params = LYT.router.getParams match[1]
      else
        params = {}
      
      params.term = jQuery.trim(decodeURI(params.term or "")) or null
      
      content = $(page).children( ":jqmData(role=content)" )
      
      LYT.catalog.attachAutocomplete $('#searchterm')
      $("#searchterm").bind "autocompleteselect", (event, ui) ->
        handleResults LYT.catalog.search(ui.item.value)
        $.mobile.changePage "#search?term=#{encodeURI ui.item.value}" , transition: "none"
      
      # this allows for bookmarkable search terms
      if params.term and $('#searchterm').val() isnt params.term
        $('#searchterm').val params.term
        handleResults LYT.catalog.search(params.term)
      else
        # TODO: Simple, rough implementation
        LYT.render.catalogLists handleResults, content
        
      $("#search-form").submit (event) ->
        $('#searchterm').blur()
        
        term = encodeURI $('#searchterm').val()
        handleResults LYT.catalog.search($('#searchterm').val())
        $.mobile.changePage "#search?term=#{term}" , transition: "none"
        
        event.preventDefault()
        event.stopImmediatePropagation()
      
  
  settings: (type, match, ui, page, event) ->
    style = jQuery.extend {}, (LYT.settings.get "textStyle" or {})
    
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
    
  
