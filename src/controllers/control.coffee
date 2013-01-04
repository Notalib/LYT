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

# TODO: Rename to controller (not control)

LYT.control =
  
  # ---------------
  # Utility methods
  
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
      LYT.var.next = window.location.hash
      window.location.hash = '#splash-upgrade'
    
    LYT.cache.write 'lyt', 'lastVersion', LYT.VERSION
    @setupEventHandlers()

  
  setupEventHandlers: ->
    $(document).one 'pageinit', ->
      goto = if LYT.var.next and not LYT.var.next.match /^#splash-upgrade/ then LYT.var.next else LYT.config.defaultPage.hash

      $('#splash-upgrade-button').on 'click', -> $.mobile.changePage goto

    $("#bookmark-add-button").on 'click', ->
      if LYT.player.segment().canBookmark
        LYT.player.book.addBookmark LYT.player.segment(), LYT.player.time
        LYT.render.bookmarkAddedNotification() 

    $("#log-off").on 'click',  -> LYT.service.logOff()

    $("#book-index").on 'click', ->
      ev = $(event.srcElement).closest(".create-listview")
      if ev.length isnt 0
        view = $.mobile.activePage.children ':jqmData(role=content)'
        book = LYT.player.book
        iterate = (items) ->
          for item in items
            if item.id == ev.attr("nodeid")
              LYT.render.createbookIndex item.children, view, book, item
              break
            else if item.children.length > 0
              iterate item.children
        if ev.attr("nodeid")?      
          if ev.attr("nodeid") is "0"
            LYT.render.createbookIndex book.nccDocument.structure, view, book
          else
            iterate book.nccDocument.structure
        else
          $.mobile.changePage "#book-player"

    $("#share-link-textarea").on 'click', -> 
      this.focus()
      this.selectionStart = 0
      this.selectionEnd = this.value.length

    $("#more-bookshelf-entries").on 'click', ->
      content = $.mobile.activePage.children(":jqmData(role=content)")
      LYT.render.loadBookshelfPage(content, LYT.bookshelf.getNextPage())

    $(window).resize -> LYT.player.refreshContent()

    $("#add-to-bookshelf-button").on 'click', ->
      LYT.loader.register "Adding book to bookshelf", LYT.bookshelf.add($("#add-to-bookshelf-button").attr("data-book-id"))
        .done( -> $.mobile.changePage LYT.config.defaultPage.hash )

    $('#instrumentation').find('button.previous').on 'click', ->
      LYT.render.instrumentationGraph()?.previousEntry()

    $('#instrumentation').find('button.next').on 'click', ->
      LYT.render.instrumentationGraph()?.nextEntry()

    $('#run-tests').one 'click', ->
      $('#run-tests').button 'disable'
      QUnit.start()

    QUnit.begin ->
      $('.test-results').text ''
      $('.test-tab').addClass 'started'
      $('.test-tab').removeClass 'error'

    QUnit.testStart (test) ->
      $('.test-results').text ": #{test.name}"

    QUnit.testDone (test) ->
      $('.test-results').text ": #{test.name}: #{test.passed}/#{test.total}"
      $('.test-tab').addClass if test.failed == 0 then 'done' else 'error'
      
    QUnit.log (event) ->
      method = if event.result then log.message else log.error
      method "Test: #{event.message}: passed: #{event.result}"

    Mousetrap.bind 'alt+ctrl+h', ->
      $.mobile.changePage "#support", transition: "none"
      return false

    Mousetrap.bind 'alt+ctrl+m', ->
      $("#bookmark-add-button").click()

  ensureLogOn: (params) ->
    deferred = jQuery.Deferred()
    if credentials = LYT.session.getCredentials()
      deferred.resolve credentials
    else
      if params?.guest?
        promise = LYT.service.logOn(LYT.config.service.guestUser, LYT.config.service.guestLogin)
        LYT.loader.register 'Logging in', deferred.promise()
        promise.done -> deferred.resolve()
        promise.fail -> deferred.reject()
      else
        LYT.var.next = window.location.hash
        $.mobile.changePage '#login'
        $(LYT.service).one 'logon:resolved', -> deferred.done()
        $(LYT.service).one 'logon:rejected', -> deferred.fail()
      
    deferred.promise()
  
  # ----------------
  # Control handlers
  
  login: (type, match, ui, page, event) ->
    $('#username').focus()
    
    $("#login-form").submit (event) ->
      $("#password").blur()
    
      process = LYT.service.logOn($("#username").val(), $("#password").val())
        .done ->
          log.message 'control: login: logOn done'
          next = LYT.var.next
          LYT.var.next = null
          next = LYT.config.defaultPage.hash if not next? or next is "#login" or next is ""
          $.mobile.changePage next
        
        .fail ->
          log.warn 'control: login: logOn failed'
          parameters =
            mode:                'bool'
            prompt:              LYT.i18n('Incorrect username or password')
            subTitle:            LYT.i18n('')
            animate:             false
            useDialogForceFalse: true
            allowReopen:         true
            useModal:            true
            buttons:             {}
          parameters.buttons[LYT.i18n('OK')] =
            click: -> # Nop
            theme: 'c'
          LYT.render.showDialog($("#login-form"), parameters)

      LYT.loader.register "Logging in", process
      
      event.preventDefault()
      event.stopPropagation()
  
  bookshelf: (type, match, ui, page, event) ->
    params = LYT.router.getParams match[1]
    promise = LYT.control.ensureLogOn params
    promise.fail -> log.error 'Control: bookshelf: unable to log in'
    promise.done ->
      content = $(page).children(":jqmData(role=content)")
  
      if LYT.bookshelf.nextPage is false
        LYT.render.loadBookshelfPage content
      else
        #loadBookshelfPage is called with view, page count and zeroAndUp set to true...  
        LYT.render.loadBookshelfPage content, LYT.bookshelf.nextPage , true 

  bookDetails: (type, match, ui, page, event) ->
    content = $(page).children( ":jqmData(role=content)" )
    if type is 'pagebeforeshow'
      content.children().hide()
    
    params = LYT.router.getParams match[1]
    promise = LYT.control.ensureLogOn params
    promise.fail -> log.error 'Control: bookDetails: unable to log in'
    promise.done ->
      if type is 'pagebeforeshow'
        process = LYT.catalog.getDetails(params.book)
          .done (details) ->
            LYT.render.hideOrShowButtons(details)
        LYT.loader.register "Loading book", process, 10
  
      if type is 'pageshow'
        process = LYT.catalog.getDetails(params.book)
          .fail (error, msg) ->
            log.message "Control: bookDetails: failed with error #{error} and msg #{msg}"
          .done (details) ->
            LYT.render.bookDetails(details, content)
            LYT.render.setPageTitle details.title
            content.children().show()
  
  # TODO: Move bookmarks list to separate page
  # TODO: Bookmarks and toc does not work properly after a forced refresh on the #book-index page. Needs to be fixed when force reloading the entire app.
  bookIndex: (type, match, ui, page, event) ->
    params = LYT.router.getParams(match[1])
    return if params?['ui-page']
    promise = LYT.control.ensureLogOn params
    promise.fail -> log.error 'Control: bookIndex: unable to log in'
    promise.done ->
      bookId = params?.book or LYT.player.book?.id
      if not bookId
        $.mobile.changePage LYT.config.defaultPage.hash
        return
      content = $(page).children ':jqmData(role=content)'
  
      # Remove any previously generated index (may be from another book)
      LYT.render.clearContent content
  
      activate = (active, inactive, handler) ->
        $(active).addClass 'ui-btn-active'
        $(inactive).removeClass 'ui-btn-active'
  
      renderBookmarks = ->
        #TODO:  Check if book is different than last time we checked...
        #return if $("#bookmark-list-button.ui-btn-active").length != 0
        activate "#bookmark-list-button", "#book-toc-button", renderIndex
        promise = LYT.Book.load bookId
        promise.done (book) -> LYT.render.bookmarks book, content
        LYT.loader.register "Loading bookmarks", promise
  
      renderIndex = ->
        #TODO:  Check if book is different than last time we checked...
        #return if $("#book-toc-button.ui-btn-active").length != 0
        activate "#book-toc-button", "#bookmark-list-button", renderBookmarks
        promise = LYT.Book.load bookId
        promise.done (book) -> LYT.render.bookIndex book, content
        LYT.loader.register "Loading index", promise
  
      $("#bookmark-list-button").click -> renderBookmarks()
      $("#book-toc-button").click -> renderIndex()
  
      renderIndex()

  bookPlayer: (type, match, ui, page, event) ->
    if type is 'pageshow'
      params = LYT.router.getParams(match[1])
      if params?.book and params.book isnt LYT.player?.book?.id
        $.mobile.changePage "#book-play?book=#{params.book}"
      else if not LYT.player.book
        $.mobile.changePage LYT.config.default.hash
      else
        LYT.player.refreshContent()
        LYT.render.setPageTitle LYT.i18n("Now playing") + " " + LYT.player.book.title
        $('.jp-play').focus()


  
  bookPlay: (type, match, ui, page, event) ->
    if type is 'pagebeforeshow'
      if not LYT.player.getStatus().paused
        LYT.player.pause()

    params = LYT.router.getParams(match[1])
    promise = LYT.control.ensureLogOn params
    promise.fail -> log.error 'Control: bookPlay: unable to get login'
    promise.done ->
      if type is 'pageshow'
        segmentUrl = params.section or null
        segmentUrl += "##{params.segment}" if params.segment
        offset = if params.offset then LYT.utils.parseOffset(params.offset) else 0
        play = (params.play is 'true') or false
        LYT.render.content.focusEasing params.focusEasing if params.focusEasing
        LYT.render.content.focusDuration parseInt params.focusDuration if params.focusDuration
  
        LYT.render.clearBookPlayer()
          
        header = $(page).children(':jqmData(role=header)')
        
        log.message "control: bookPlay: loading book #{params.book}"
        
        process = LYT.player.load params.book, segmentUrl, offset, play
        LYT.loader.register "Loading book", process
        process.done (book) ->
          LYT.render.bookPlayer book, $(page)
          #see if there are any announcements....each time we have loaded a new book.....
          LYT.service.getAnnouncements()
          $.mobile.changePage "#book-player?book=#{LYT.player.book.id}"
  
        process.fail (error) ->
          log.error "Control: bookPlay: Failed to load book ID #{params.book}, reason: #{error}"
          
          # Hack to fix books not loading when being redirected directly from login page
          if LYT.session.getCredentials()?
            if LYT.var.next? and ui.prevPage[0]?.id is 'login'
              window.location.reload()
            else
              parameters =
                mode:                'bool'
                prompt:              LYT.i18n('Unable to retrieve book')
                subTitle:            LYT.i18n('')
                animate:             false
                useDialogForceFalse: true
                allowReopen:         true
                useModal:            true
                buttons: {}
              parameters.buttons[LYT.i18n('Try again')] =
                click: -> window.location.reload()
                icon:  'refresh'
                theme: 'c'
              parameters.buttons[LYT.i18n('Cancel')] =
                click: -> $.mobile.changePage LYT.config.defaultPage.hash
                icon:  'delete'
                theme: 'c'
              LYT.render.showDialog($.mobile.activePage, parameters)
  
  search: (type, match, ui, page, event) ->
    params = LYT.router.getParams(match[1])
    promise = LYT.control.ensureLogOn params
    promise.fail -> log.error 'Control: search: unable to log in'
    promise.done ->
      if type is 'pagebeforeshow'
        content = $(page).children(":jqmData(role=content)")
        content.children().hide()

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

        # determine action and parse params: predefinedView, search, predefinedSearch
        action = "predefinedView"
        if not jQuery.isEmptyObject params
          if params.term?
            [action, term] = ["search", jQuery.trim(decodeURIComponent(params.term or "") ) ]
          else if params.list?
            list = jQuery.trim(decodeURIComponent(params.list or "") )
            action = "showList" if LYT.predefinedSearches[list]?

        content = $(page).children( ":jqmData(role=content)" )
        header = $(page).children( ":jqmData(role=header)" ).find("h1")
        
        switch action
          when "predefinedView"
            $('#listshow-btn').hide()
            $('#more-search-results').hide()
            $('#searchterm').val ''
            LYT.render.setHeader page, "Search"
            LYT.render.catalogLists content
          when "search"
            LYT.render.setHeader page, "Search"
            $('#searchterm').val term
            handleResults LYT.catalog.search(term)
          when "showList"
            LYT.render.setHeader page, LYT.predefinedSearches[list].title 
            handleResults LYT.predefinedSearches[list].callback()

        LYT.catalog.attachAutocomplete $('#searchterm')
        # When hitting enter in dropdown, submit.
        $("#searchterm").unbind "autocompleteselect"
        $("#searchterm").bind "autocompleteselect", (event, ui) ->
          $('#search-form').trigger('submit')

        $("#search-form").submit (event) ->
          $('#searchterm').blur()
          term = encodeURIComponent $('#searchterm').val()
          $.mobile.changePage "#search?term=#{term}", transition: "none"
          event.preventDefault()
          event.stopImmediatePropagation()

        $('#searchterm').focus()
      
  settings: (type, match, ui, page, event) ->
    params = LYT.router.getParams(match[1])
    promise = LYT.control.ensureLogOn params
    promise.fail -> log.error 'Control: settings: unable to log in'
    promise.done ->
      if type is 'pagebeforeshow'
        promise = LYT.player.isPlayBackRateSupported()
        promise.done (result) ->
          if not result 
            LYT.render.hideplayBackRate()
        promise.fail () ->
           LYT.render.hideplayBackRate()   
  
      if type is 'pageshow'
        style = jQuery.extend {}, (LYT.settings.get "textStyle" or {})
        
        $("#style-settings").find("input").each ->
          name = $(this).attr 'name'
          val = $(this).val()
          
          # Setting the GUI
          switch name 
            when 'font-size', 'font-family'
              if val is style[name]
                $(this).attr("checked", true).checkboxradio("refresh");
            when 'marking-color'
              colors = val.split(';')
              if style['background-color'] is String(colors[0]) and style['color'] is String(colors[1])
                $(this).attr("checked", true).checkboxradio("refresh");
            when 'playback-rate'  
              if Number(val) is LYT.settings.get('playBackRate')
                $(this).attr("checked", true).checkboxradio("refresh");

        # Saving the GUI       
        # TODO: The change handler below is being bound once for every time we
        #       enter this page.
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
            # TODO: use lower case just like all the other parameters
            when 'playback-rate'
              val = Number(val)
              LYT.settings.set('playBackRate', val)
              LYT.player.setPlayBackRate val
                  
          LYT.settings.set('textStyle', style)
          LYT.render.setStyle()
  
  profile: (type, match, ui, page, event) ->
    # Not passing params since it is currently only being used to indicate
    # whether the user should be logged in as guest.
    promise = LYT.control.ensureLogOn()
    promise.fail -> log.error 'Control: profile: unable to log in'
    promise.done ->
      if type is 'pageshow'
        LYT.render.profile()
        
  share: (type, match, ui, page, event) ->
    params = LYT.router.getParams(match[1])
    promise = LYT.control.ensureLogOn params
    promise.fail -> log.error 'Control: share: unable to log in'
    promise.done ->
      if type is 'pageshow'
        params = LYT.router.getParams match[1]
        if jQuery.isEmptyObject params
          if segment = LYT.player.segment()
            params = 
              title:   segment.section.nccDocument.book.title
              book:    segment.section.nccDocument.book.id
              section: segment.section.url
              segment: segment.id
              offset:  LYT.utils.formatTime(LYT.player.time)
          else
            defaultPage()

        url = LYT.router.getBookActionUrl params
        urlEmail = url.replace("&", "&amp;")
        subject = LYT.i18n 'Link to book at E17'
        # Sorry about the clumsy english below, but it has to translate directly to danish without changing the position of the title and url
        body = "#{LYT.i18n('Listen to')} #{params.title} #{LYT.i18n('by clicking this link')}: #{escape urlEmail}"
        
        $("#email-bookmark").attr('href', "mailto: ?subject=#{subject}&body=#{body}")
        
        $("#share-link-textarea").text url
        
        
  instrumentation: (type, match, ui, page, event) ->
    if type is 'pagebeforeshow'
      LYT.render.showInstrumentation $('#instrumentation-content') 
      
  test:  (type, match, ui, page, event) ->
    if type is 'pageshow'
      LYT.render.hideTestTab()
    else if type is 'pagehide'
      LYT.render.showTestTab()

  suggestions: -> $.mobile.changePage("#search?list=anbe")

  guest: -> $.mobile.changePage(LYT.config.defaultPage.hash+'?guest=true')

  defaultPage: -> $.mobile.changePage(LYT.config.defaultPage.hash)
