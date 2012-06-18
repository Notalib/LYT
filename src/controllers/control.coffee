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
          log.message 'logon done'

          
          if not LYT.var.next? or LYT.var.next is "#login" or LYT.var.next is ""
            LYT.var.next = "#bookshelf"
          
          $.mobile.changePage LYT.var.next
        
        .fail ->
          log.message "log on failure"
          $("#login-form").simpledialog({
                'mode' : 'bool',
                'prompt' : 'Log ind fejl!',
                'subTitle' : 'Forkert brugernavn eller kodeord.'
                'animate': false,
                'useDialogForceFalse': true,
                'allowReopen': true,
                'useModal': true,
                'buttons' : {
                  'OK': 
                    click: (event) ->
                    ,
                    theme: "c"
                  ,  
                }
          })
          
 
       
        
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
    if type is 'pagebeforeshow'
      LYT.render.hideOrShowButtons()
    if type is 'pageshow'
      params = LYT.router.getParams(match[1])
      content = $(page).children( ":jqmData(role=content)" )
      
      process = LYT.catalog.getDetails(params.book)
        .done (details) ->
          LYT.render.bookDetails(details, content)
          
          content.find("#add-to-bookshelf-button").bind "click", (event) ->
            # TODO: This is far from perfect: There's no way
            # of knowing if something's already on the shelf
            if(LYT.session.getCredentials().username is LYT.config.service.guestLogin)
              $(this).simpledialog({
                'mode' : 'bool',
                'prompt' : 'Du er logget på som gæst!',
                'subTitle' : '...og kan derfor ikke tilføje bøger.'
                'animate': false,
                'useDialogForceFalse': true,
                'allowReopen': true,
                'useModal': true,
                'buttons' : {
                  'OK': 
                    click: (event) ->
                    ,
                    theme: "c"
                  ,  
                }
              })

            else
              LYT.loader.register "Adding book to bookshelf", LYT.bookshelf.add(params.book).done( -> $.mobile.changePage "#bookshelf" )
              $(this).unbind event 
              event.preventDefault()
              event.stopImmediatePropagation()
        
        .fail (error, msg) ->
          log.message "failed with error #{error} and msg #{msg}"
      
      LYT.loader.register "Loading book", process
  
  bookIndex: (type, match, ui, page, event) ->
    if type is 'pagebeforeshow'
      return unless match[1] # Hack to avoid eternal pageloading on jqm subpages
      
      params = LYT.router.getParams(match[1])
      content = $(page).children( ":jqmData(role=content)" )
      
      #log.message ui.prevPage[0]?.id

      if ui.prevPage[0]?.id is 'book-play'
        LYT.render.ClearIndex(content)
        #log.message 'clear-index'


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
      offset = Number(params.offset) or 0
      guest = params.guest or null
      autoplay = params.autoplay or false

      if guest is null and LYT.session.getCredentials() is null and LYT.var.next? #logged off
         window.location.reload()

      if guest? and LYT.session.getCredentials() is null
         process = LYT.service.logOn(LYT.config.service.guestUser, LYT.config.service.guestLogin)
           .done ->
             return $.mobile.changePage "#book-play?book=#{params.book}&section=#{params.section}&offset=#{params.offset}"
        
      
      # if book and section is the same as what is currently playing don't do anything new here
      if LYT.player.book?    
        if LYT.player.book.id is params.book and LYT.session.getCredentials() isnt null
          # this book is already playing maybe we should not change anything unless logedoff
          if not section? or not LYT.player.section?
            # section is either not defined in url or in book 
            return
          else if section is LYT.player.section.id
            # section is the same as already playing don't chaneg anything
            return
          else
           # this is a new section - load it
      
      LYT.player.clear()
      LYT.render.clearBookPlayer()
        
      header = $(page).children( ":jqmData(role=header)")
      $('#book-index-button').attr 'href', """#book-index?book=#{params.book}"""    
      
      process = LYT.Book.load(params.book, section, offset)
        .done (book) -> 
          
          LYT.render.bookPlayer book, $(page)
          #no section or offset from link 
          if not section and offset is 0 and book.lastmark?
            log.message "Found lastmark. Resuming play at section #{book.lastmark.section} and offset #{book.lastmark.offset}"
            url     = book.lastmark.URL
            offset  = book.lastmark.offset
          log.message autoplay
          if autoplay is "true"
            LYT.player.load book, url, offset, true #autoplay  
          else
            LYT.player.load book, url, offset, false #no autoplay

          #see if there are any announcements....each time we loaded a new book.....
        
          LYT.service.getAnnouncements()

          
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
          if LYT.session.getCredentials()?
            if LYT.var.next? and ui.prevPage[0]?.id is 'login'
              window.location.reload()
            else
              $("#submenu").simpledialog({
                'mode' : 'bool',
                'prompt' : 'Der er opstået en fejl!',
                'subTitle' : 'kunne ikke hente bogen.'
                'animate': false,
                'useDialogForceFalse': true,
                'allowReopen': true,
                'useModal': true,
                'buttons' : {
                  'Prøv igen': 
                    click: (event) ->
                      window.location.reload()
                    icon: "refresh",
                    theme: "c"
                  ,
                  'Annuller': 
                    click: (event) ->
                      $.mobile.changePage "#bookshelf"
                    icon: "delete",
                    theme: "c"
                  ,
                   
                }
              
              })
            #$("#submenu").trigger('simpledialog', {'method': 'open'})              
              #response = confirm 'kunne ikke hente bogen, vil du prøve igen?'
             # if(response)
              #  window.location.reload()
              #else
             #   $.mobile.changePage "#bookshelf"
            
      
      LYT.loader.register "Loading book", process

  
  search: (type, match, ui, page, event) ->
    if type is 'pageshow'
      

      $("#listshow-btn").click (event) ->
        LYT.var.callback = null
        content = $(page).children(":jqmData(role=content)")
        LYT.render.catalogLists handleResults, content
        $('#searchterm').val ""
        $('#listshow-btn').hide()
        $('#more-search-results').hide()
        

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
        LYT.var.searchTerm = params
      else
        if LYT.var.searchTerm?
          log.message LYT.var.searchTerm
          params = LYT.var.searchTerm
          handleResults LYT.catalog.search(params.term)
        else
          params = {}

      #search?list=???
      list = params.list or null  

      params.term = jQuery.trim(decodeURI(params.term or "")) or null
      
      content = $(page).children( ":jqmData(role=content)" )

      LYT.catalog.attachAutocomplete $('#searchterm')
      # selecting the item from the autocompleteselect list....
      $("#searchterm").bind "autocompleteselect", (event, ui) ->
        handleResults LYT.catalog.search(ui.item.value)
        $.mobile.changePage "#search?term=#{encodeURI ui.item.value}" , transition: "none"
      
      # this allows for bookmarkable/direct search terms
      if params.term and $('#searchterm').val() isnt params.term
        $('#searchterm').val params.term
        handleResults LYT.catalog.search(params.term)
      else if list?
      #Direct link to lists
        switch list
          when 'anbe' then list = "list_item_1"
          when 'ny' then list = "list_item_2"
          when 'top' then list = "list_item_3"
          when 'topu' then list = "list_item_4"
          when 'topv' then list = "list_item_5"
          else
            LYT.render.catalogLists handleResults, content  

        LYT.render.catalogListsDirectlink handleResults, content, list
      else if LYT.var.callback?
        
      else
        # TODO: Simple, rough implementation - show lists....
        $('#listshow-btn').hide()
        $('#more-search-results').hide()
        LYT.render.catalogLists handleResults, content

        
      $("#search-form").submit (event) ->
        $('#searchterm').blur()
        #autoGoogle = LYT.google.DoAutoComplete($('#searchterm').val())
          #.done (jsonResults)->
            #LYT.render.showDidYouMean jsonResults, content

          #.fail ->
            
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
          if style['background-color'] is String(colors[0]) and style['color'] is String(colors[1])
            #log.message 'her'
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
    if type is 'pageshow'
      LYT.render.profile()
      
      $("#log-off").click (event) ->
        LYT.service.logOff()
        
  share:(type, match, ui, page, event) ->
    if type is 'pageshow'
      #log.message LYT.player.book
      if LYT.player.getCurrentlyPlaying()?#if no book and no section
        subject = "Link til bog på E17"
        if LYT.player.isIOS()#nice html... 
          body = "Hør #{LYT.player.book.title} ved at følge dette link: <a href='#{LYT.player.getCurrentlyPlayingUrl(true,'offset')}'>#{LYT.player.book.title}</a>"
        else
          body = "Hør #{LYT.player.book.title} ved at følge dette link: #{LYT.player.getCurrentlyPlayingUrl(true,'offset')}"
          # body...
        
        $("#email-bookmark").attr('href', "mailto:?subject=#{subject}&body=#{body.replace(/&/gi,'%26')}")
        
        $("#share-link-textarea").text LYT.player.getCurrentlyPlayingUrl(true,'offset')
        $("#share-link-textarea").click -> 
          this.focus()
          if LYT.player.isIOS()
            this.selectionStart=0;
            this.selectionEnd= this.value.length;
          else
            this.select()  
          
        
      else
        $.mobile.changePage("#bookshelf") #no book go to bookshelf
        

  anbefal: (type)->
    $.mobile.changePage("#search?list=anbe")

  guest: (type)->
    process = LYT.service.logOn(LYT.config.service.guestUser, LYT.config.service.guestLogin)
      .done ->
        return $.mobile.changePage("#bookshelf")
