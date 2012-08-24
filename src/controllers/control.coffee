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
      params = LYT.router.getParams(match[1])
      process = LYT.catalog.getDetails(params.book)
        .done (details) ->
          LYT.render.hideOrShowButtons(details)

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
    return unless match[1] # Hack to avoid eternal pageloading on jqm subpages
    params = LYT.router.getParams(match[1])
    content = $(page).children( ":jqmData(role=content)" )

    switch type
      when 'pagebeforeshow'
        # Remove any previously generated index (may be from another book)
        if ui.prevPage[0]?.id is 'book-play'
          LYT.render.ClearIndex(content)
          #log.message 'clear-index'

      when 'pageshow'
        activate = (active, inactive, handler) ->
          $(active).unbind "click"
          $(active).css 'background-color', '#ffffff'
          $(inactive).css 'background-color', ""
          $(inactive).unbind "click"
          $(inactive).click (event) -> handler(event)
    
        renderBookmarks = ->
          activate "#bookmark-list-button", "#book-toc-button", renderIndex
          promise = LYT.Book.load params.book
          promise.done (book) -> LYT.render.bookmarks book, content
          LYT.loader.register "Loading bookmarks", promise
    
        renderIndex = ->
          activate "#book-toc-button", "#bookmark-list-button", renderBookmarks
          promise = LYT.Book.load params.book
          promise.done (book) -> LYT.render.bookIndex book, content
          LYT.loader.register "Loading index", promise
    
        renderIndex()

  
  bookPlayer: (type, match, ui, page, event) ->
    if type is 'pageshow'
      params = LYT.router.getParams(match[1])
      segmentUrl = params.section or null
      segmentUrl += "##{params.segment}" if params.segment
      offset = if params.offset then LYT.utils.parseOffset(params.offset) else 0
      guest = params.guest or null
      autoplay = params.autoplay or false
      LYT.render.content.focusEasing params.focusEasing if params.focusEasing
      LYT.render.content.focusDuration parseInt params.focusDuration if params.focusDuration

      if guest is null and LYT.session.getCredentials() is null and LYT.var.next? #logged off
         window.location.reload()

      if guest? and LYT.session.getCredentials() is null
         process = LYT.service.logOn(LYT.config.service.guestUser, LYT.config.service.guestLogin).done ->
           return $.mobile.changePage "#book-play?book=#{params.book}&section=#{params.section}&segment=#{params.segment}&offset=#{params.offset}"
        
      return unless LYT.session.getCredentials()?
      # This doesn't make any sense:
      # return unless LYT.player.book? is params.book and LYT.player.segment()?.url is segmentUrl
      
      LYT.player.clear()
      LYT.render.clearBookPlayer()
        
      header = $(page).children( ":jqmData(role=header)")
      $('#book-index-button').attr 'href', """#book-index?book=#{params.book}"""    
      
      process = LYT.player.load(params.book, segmentUrl, offset, true)
        .done (book) -> 
          LYT.render.bookPlayer book, $(page)

          #see if there are any announcements....each time we loaded a new book.....
        
          LYT.service.getAnnouncements()

          $("#bookmark-add-button").unbind "click"
          $("#bookmark-add-button").click (event) ->
            if segment = LYT.player.segment()
              LYT.player.book.addBookmark segment, LYT.player.time
              LYT.render.bookmarkAddedNotification()
          
          ###
          $("#book-play").bind "swiperight", ->
              LYT.player.nextSection()
          
          $("#book-play").bind "swipeleft", ->
              LYT.player.previousSection()
          ###
        
        .fail () ->
          log.error "Control: Failed to load book ID #{params.book}"
          
          # Hack to fix books not loading when being redirected directly from login page
          if LYT.session.getCredentials()?
            if LYT.var.next? and ui.prevPage[0]?.id is 'login'
              window.location.reload()
            else
              $.mobile.activePage.simpledialog({
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
          log.message "control.search: #{LYT.var.searchTerm}"
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
    if type is 'pagebeforeshow'
      if not LYT.player.isPlayBackRateSurpported()
        LYT.render.hideplayBackRate()

    if type is 'pageshow'
      style = jQuery.extend {}, (LYT.settings.get "textStyle" or {})
      
      $("#style-settings").find("input").each ->
        name = $(this).attr 'name'
        val = $(this).val()
        
        #setting the GUI
        switch name 
          when 'font-size', 'font-family'
            if val is style[name]
              $(this).attr("checked", true).checkboxradio("refresh");
          when 'marking-color'
            colors = val.split(';')
            if style['background-color'] is String(colors[0]) and style['color'] is String(colors[1])
              $(this).attr("checked", true).checkboxradio("refresh");
       #Saving th GUI       
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
          when 'playBack-Rate'
            speed_lookup = ['slow', 'normal_slow', 'normal', 'fast', 'fast_ultra']
            if speed_key = speed_lookup[val - 1]
              LYT.player.setPlayBackRate(LYT.config.player.readSpeed[speed_key])
            else
              log.error "Control: setting playback rate to #{val} failed"
                
        LYT.settings.set('textStyle', style)
        LYT.render.setStyle()
  
  profile: (type, match, ui, page, event) ->
    if type is 'pageshow'
      LYT.render.profile()
      
      $("#log-off").click (event) ->
        LYT.service.logOff()
        
  share: (type, match, ui, page, event) ->
    if type is 'pageshow'
      params = LYT.router.getParams match[1]
      if jQuery.isEmptyObject params
        if segment = LYT.player.segment()
          params = 
            title:   segment.section.nccDocument.book.title
            book:    segment.section.nccDocument.book.id
            section: segment.section.url
            segment: segment.id
            offset:  LYT.player.time 
        else
          $.mobile.changePage("#bookshelf") #no book go to bookshelf
      url = LYT.router.getBookActionUrl params
      subject = "Link til bog på E17"
      if LYT.player.isIOS() #nice html... 
        body = "Hør #{params.title} ved at følge dette link: <a href='#{url}'>#{params.title}</a>"
      else
        body = "Hør #{params.title} ved at følge dette link: #{url}"
        # body...
      
      $("#email-bookmark").attr('href', "mailto:?subject=#{subject}&body=#{body.replace(/&/gi,'%26')}")
      
      $("#share-link-textarea").text url
      $("#share-link-textarea").click -> 
        this.focus()
        if LYT.player.isIOS()
          this.selectionStart=0;
          this.selectionEnd= this.value.length;
        else
          this.select()  
        
  anbefal: (type)->
    $.mobile.changePage("#search?list=anbe")

  guest: (type)->
    process = LYT.service.logOn(LYT.config.service.guestUser, LYT.config.service.guestLogin)
      .done ->
        return $.mobile.changePage("#bookshelf")
