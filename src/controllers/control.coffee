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
  
  init: ->
    lastVersion = ->
      # For debugging: let the user specify lastVersion in the address
      if match = window.location.hash.match /lastVersion=([0-9\.]+)/
        return match[1]
      if version = LYT.cache.read 'lyt', 'lastVersion'
        return version
      if LYT.cache.read 'session', 'credentials' or LYT.cache.read 'lyt', 'settings'
        return '0.0.2'
          
    if lastVersion() and lastVersion() isnt LYT.VERSION
      next = window.location.hash
      window.location.hash = '#splash-upgrade'
    
    LYT.cache.write 'lyt', 'lastVersion', LYT.VERSION
    @clickHandlers()



  clickHandlers: ->
    $(document).one 'pageinit', ->
      $('#splash-upgrade-button').on 'click', -> $.mobile.changePage(next or '#bookshelf')

    $("#bookmark-add-button").on 'click', ->
      if LYT.player.segment().canBookmark
        LYT.player.book.addBookmark LYT.player.segment(), LYT.player.time
        LYT.render.bookmarkAddedNotification() 

    $("#log-off").on 'click',  -> LYT.service.logOff()

    $("#share-link-textarea").on 'click', -> 
      this.focus()
      if LYT.player.isIOS()
        this.selectionStart = 0
        this.selectionEnd = this.value.length
      else
        this.select()

    $("#more-bookshelf-entries").on 'click', ->
      content = $.mobile.activePage.children(":jqmData(role=content)")
      LYT.render.loadBookshelfPage(content, LYT.bookshelf.getNextPage())
      #event.preventDefault()
      #event.stopImmediatePropagation()

  
  login: (type, match, ui, page, event) ->
    $("#login-form").submit (event) ->
      $("#password").blur()
    
      process = LYT.service.logOn($("#username").val(), $("#password").val())
        .done ->
          log.message 'control: login: logOn done'
          next = LYT.var.next
          LYT.var.next = null
          next = "#bookshelf" if not next? or next is "#login" or next is ""
          $.mobile.changePage next
        
        .fail ->
          log.warn 'control: login: logOn failed'
          parameters = {
            'mode': 'bool',
            'prompt': LYT.i18n('Login error'),
            'subTitle' : LYT.i18n('Incorrect username or password'),
            'animate': false,
            'useDialogForceFalse': true,
            'allowReopen': true,
            'useModal': true,
            'buttons': {}
          }
          parameters['buttons'][LYT.i18n('OK')] = {
            click: (event) ->
            ,
            theme: "c"
                  ,  
          }
          $("#login-form").simpledialog(parameters)
        
      LYT.loader.register "Logging in", process
      
      event.preventDefault()
      event.stopPropagation()
    
  
  bookshelf: (type, match, ui, page, event) ->
    if type is 'pageshow'
      content = $(page).children(":jqmData(role=content)")

      if LYT.bookshelf.nextPage is false
        LYT.render.loadBookshelfPage content
      else
        #loadBookshelfPage is called with view, page count and zeroAndUp set to true...  
        LYT.render.loadBookshelfPage content, LYT.bookshelf.nextPage , true 

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
              parameters = {
                'mode' : 'bool',
                'prompt' : LYT.i18n('You are logged in as guest!'),
                'subTitle' : '...' + LYT.i18n('and hence cannot add books'),
                'animate': false,
                'useDialogForceFalse': true,
                'allowReopen': true,
                'useModal': true,
                'buttons' : {}
              }
              parameters['buttons'][LYT.i18n('OK')] = {
                'OK': 
                  click: (event) ->
                  ,
                  theme: "c"
                ,  
              }
              $(this).simpledialog(parameters)

            else
              LYT.loader.register "Adding book to bookshelf", LYT.bookshelf.add(params.book).done( -> $.mobile.changePage "#bookshelf" )
              $(this).unbind event 
              event.preventDefault()
              event.stopImmediatePropagation()
        
        .fail (error, msg) ->
          log.message "failed with error #{error} and msg #{msg}"
      
      LYT.loader.register "Loading book", process
  
  # TODO: Move bookmarks list to separate page
  bookIndex: (type, match, ui, page, event) ->
    params = LYT.router.getParams(match[1])
    return if params?['ui-page']
    bookId = params?.book or LYT.player.book?.id
    $.mobile.changePage '#bookshelf' unless bookId
    content = $(page).children ':jqmData(role=content)'

    # Remove any previously generated index (may be from another book)
    LYT.render.clearContent content

    activate = (active, inactive, handler) ->
      # TODO: We shouldn't have to re-bind every time a page is shown
      $(active).unbind 'click'
      $(inactive).unbind 'click'
      $(active).addClass 'ui-btn-active'
      $(inactive).removeClass 'ui-btn-active'
      $(inactive).click (event) -> handler event

    renderBookmarks = ->
      activate "#bookmark-list-button", "#book-toc-button", renderIndex
      promise = LYT.Book.load bookId
      promise.done (book) -> LYT.render.bookmarks book, content
      LYT.loader.register "Loading bookmarks", promise

    renderIndex = ->
      activate "#book-toc-button", "#bookmark-list-button", renderBookmarks
      promise = LYT.Book.load bookId
      promise.done (book) -> LYT.render.bookIndex book, content
      LYT.loader.register "Loading index", promise

    renderIndex()

  bookPlayer: (type, match, ui, page, event) ->
    if type is 'pageshow'
      params = LYT.router.getParams(match[1])
      if params?.book and params.book isnt LYT.player?.book?.id
        $.mobile.changePage "#book-play?book=#{params.book}"
      else if not LYT.player.book
        $.mobile.changePage "#bookshelf"
  
  bookPlay: (type, match, ui, page, event) ->
    if type is 'pageshow'
      params = LYT.router.getParams(match[1])
      segmentUrl = params.section or null
      segmentUrl += "##{params.segment}" if params.segment
      offset = if params.offset then LYT.utils.parseOffset(params.offset) else 0
      guest = params.guest or null
      autoplay = params.autoplay or false
      LYT.render.content.focusEasing params.focusEasing if params.focusEasing
      LYT.render.content.focusDuration parseInt params.focusDuration if params.focusDuration

      if LYT.session.getCredentials() is null
        if guest?
          process = LYT.service.logOn(LYT.config.service.guestUser, LYT.config.service.guestLogin).done ->
            $.mobile.changePage "#book-play?book=#{params.book}&section=#{params.section}&segment=#{params.segment}&offset=#{params.offset}"
        else
          if LYT.var.next?
            window.location.reload()
          else
            LYT.var.next = window.location.hash
            $.mobile.changePage '#login'
            return
      
      LYT.player.pause()
      LYT.render.clearBookPlayer()
        
      header = $(page).children(':jqmData(role=header)')
      
      log.message "control: bookPlay: loading book #{params.book}"
      
      process = LYT.player.load params.book, segmentUrl, offset, true
      LYT.loader.register "Loading book", process
      process.done (book) ->
        LYT.render.bookPlayer book, $(page)
        #see if there are any announcements....each time we have loaded a new book.....
        LYT.service.getAnnouncements()
        $.mobile.changePage "#book-player?book=#{LYT.player.book.id}"

      process.fail (error) ->
        log.error "Control: Failed to load book ID #{params.book}, reason: #{error}"
        
        # Hack to fix books not loading when being redirected directly from login page
        if LYT.session.getCredentials()?
          if LYT.var.next? and ui.prevPage[0]?.id is 'login'
            window.location.reload()
          else
            parameters = {
              'mode': 'bool',
              'prompt': LYT.i18n('An error has occurred!'),
              'subTitle': LYT.i18n('unable to retrieve book'),
              'animate': false,
              'useDialogForceFalse': true,
              'allowReopen': true,
              'useModal': true,
              'buttons': {}
            }
            parameters['buttons'][LYT.i18n('Try again')] = {
              click: (event) ->
                window.location.reload()
              icon: "refresh",
              theme: "c"
            }
            parameters['buttons'][LYT.i18n('Cancel')] = {
              click: (event) ->
                $.mobile.changePage "#bookshelf"
              icon: "delete",
              theme: "c"
            }
            $.mobile.activePage.simpledialog(parameters)

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
          log.message "control: search: #{LYT.var.searchTerm}"
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
      if not LYT.player.isPlayBackRateSupported()
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
       #Saving the GUI       
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
      # Sorry about the clumsy enlish below, but it has to translate directly to danish without changing the position of the title and url
      if LYT.player.isIOS() #nice html... 
        body = "#{LYT.i18n('Listen to')} #{params.title} #{LYT.i18n('by clicking this link')}: <a href='#{url}'>#{params.title}</a>"
      else
        body = "#{LYT.i18n('Listen to')} #{params.title} #{Lyt.i18n('by clicking this link')}: #{url}"
        # body...
      
      $("#email-bookmark").attr('href', "mailto:?subject=#{subject}&body=#{body.replace(/&/gi,'%26')}")
      
      $("#share-link-textarea").text url
      $("#share-link-textarea").click -> 
        this.focus()
        if LYT.player.isIOS()
          this.selectionStart = 0;
          this.selectionEnd = this.value.length;
        else
          this.select()  
        
  anbefal: (type)->
    $.mobile.changePage("#search?list=anbe")

  guest: (type)->
    process = LYT.service.logOn(LYT.config.service.guestUser, LYT.config.service.guestLogin)
      .done ->
        return $.mobile.changePage("#bookshelf")
    
  