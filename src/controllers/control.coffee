# Requires `/common`
# Requires `/support/lyt/loader`
# Requires `/models/book/book`
# Requires `/models/member/settings`
# Requires `/models/service/service`
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
    @setupEventHandlers()

  setupEventHandlers: ->
    # Hook up the "close player" button
    $("#close-player-button").on 'click', ->
      if window.frameElement
        frame = $(window.frameElement)
        frame.fadeOut -> frame.remove()
      else if LYT.config.navigation?.backButtonURL and LYT.player.book?.id
        id = LYT.player.book.id
        tmplUrl = LYT.config.navigation.backButtonURL

        url = LYT.utils.renderTemplate tmplUrl, id: id
        window.location.href = url
      else
        window.history.go -1

    $("#bookmark-add-button").on 'click', ->
      if (segment = LYT.player.currentSegment) and segment.canBookmark
        LYT.player.book.addBookmark segment, LYT.player.getStatus().currentTime
        LYT.render.bookmarkAddedNotification()
        LYT.render.bookmarks LYT.player.book, true

    # Emulate "click" with enter
    $('#navigation a[role=button]').keypress (e) ->
      $(this).click() if e.which is 13

    # Initialize tabs on the sidebar
    tabs = $('#sidebar li[role="tab"]')
    panes = $('#sidebar div[role="tabpanel"]')
    tabs.click () ->
      tabs.attr 'aria-selected', false
      @setAttribute 'aria-selected', true
      paneid = @getAttribute 'aria-controls'
      pane = $('#' + paneid)
      panes.attr 'aria-hidden', true
      pane.attr 'aria-hidden', false

    # Listen for updates on section changes, and update the index
    # when neccesary
    $(LYT.player).on 'beginSection', (e) ->
      section = e.value
      LYT.render.activeIndexSection section

    $('#settings-button').on 'click', (e) ->
      e.stopPropagation()
      oldPopup = $('.settings-popup')

      if oldPopup.length and oldPopup.is(':visible')
        return LYT.render.closeSettingsPopup()
      else
        isFirst = true

      closeListener = (e) ->
        if !jQuery.contains(popup[0], e.target)
          LYT.render.closeSettingsPopup()

      $(document).off('click', closeListener).on('click', closeListener)

      popup = LYT.render.openSettingsPopup()

      style = jQuery.extend {}, (LYT.settings.get "textStyle" or {})
      LYT.render.updateSettingsPopup style

      # Attach event listeners if this is the first time the settings
      # popup is opened
      if isFirst
        popup.find('#fontsize_dec_button,#fontsize_inc_button').click (e) ->
          e.stopPropagation()
          style = jQuery.extend {}, (LYT.settings.get "textStyle" or {})
          size = parseInt style['font-size'], 10

          if e.target.id is 'fontsize_dec_button'
            size--
          else
            size++

          style['font-size'] = size + 'px'
          LYT.settings.set 'textStyle', style
          LYT.render.setStyle()

        # For whatever reason 'change' event doesn't work(?!)
        popup.find('input').click (e) ->
          e.stopPropagation()
          target = $(this)
          name = target.attr 'name'
          val = target.val()

          style = jQuery.extend {}, (LYT.settings.get "textStyle" or {})

          switch name
            when 'font-family'
              style[name] = val
            when 'marking-color'
              colors = val.split(';')
              style['background-color'] = colors[0]
              style['color'] = colors[1]
              # TODO: use lower case just like all the other parameters
            when 'playback-rate'
              val = Number(val)
              LYT.settings.set('playbackRate', val)
              LYT.player.setPlaybackRate val
            when 'word-highlighting'
              isOn = target.prop "checked"
              LYT.render.setHighlighting isOn
              LYT.settings.set('wordHighlighting', isOn)

          LYT.settings.set('textStyle', style)
          LYT.render.setStyle()

    $(window).resize -> LYT.player.refreshContent()

    $("#login-form").submit (e) ->
      e.preventDefault()
      e.stopPropagation()

      $form = $(this)
      $form.find("#password").blur()

      process = LYT.service.logOn($form.find("#username").val(), $form.find("#password").val())
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

      # Clear password field
      $form.find('#password').val ''

      LYT.loader.register "Logging in", process

    Modernizr.on 'playbackratelive', (playbackratelive) ->
      if not Modernizr.playbackrate and not playbackratelive
        LYT.render.disablePlaybackRate()

    $('#run-tests').one 'click', ->
      $('#run-tests').button 'disable'
      deferred = $.mobile.util.waitForConfirmDialog LYT.i18n('Is this the first test run?')
        .done ->
          LYT.settings.reset()
          LYT.player.setPlaybackRate 1
        .always ->
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
      test_name = test.name.replace /\s+/g, '_'
      LYT.test.fixtures.results[test_name] or= []
      (test.assertions or []).forEach (assertion) ->
        LYT.test.fixtures.results[test_name].push assertion

    QUnit.done ->
      $.post '/test/results',
        userAgent: navigator.userAgent
        testResults: LYT.test.fixtures.results
      $.mobile.changePage "#test"

    QUnit.log (event) ->
      method = if event.result then log.message else log.error
      method "Test: #{event.message}: passed: #{event.result}"

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
    $page = $(page)
    if type is 'pageshow'
      $page.find('#username').focus()
      $page.find('#submit').button('enable')
    else
      $page.find('#submit').button('disable')

  bookPlayer: (type, match, ui, page, event) ->
    params = LYT.router.getParams(match[1])
    if not params? or not params.book?
      return

    if type is 'pagebeforeshow'
      # Make sure we're looking good
      LYT.render.setStyle()

      # Stop playback if we are going to switch to another book
      if LYT.player.book?.id and params.book isnt LYT.player.book.id
        LYT.player.stop()
        LYT.render.clearBookPlayer()

    promise = LYT.control.ensureLogOn params
    promise.fail -> log.error 'Control: bookPlay: unable to get login'
    promise.done ->
      if type is 'pageshow'
        LYT.player.refreshContent(true) if LYT.player.book?.id is params.book

        # Switch to different (part of) book
        # Because of bad naming, sections are here actually SMIL
        # files with an optional fragment. We're keeping params.section
        # for backwards-compatibility
        if params.smil or params.section
          smil = params.smil or params.section
          smilReference = smil
          if params.fragment
            smilReference += "##{params.fragment}"
          else if params.segment
            smilReference += "##{params.segment}"

          offset = if params.offset then LYT.utils.parseTime(params.offset) else null
        else if LYT.player.book?.id is params.book
          # We're already playing this book, so we just continue playing.
          return

        play = params.play is 'true'
        LYT.render.content.focusEasing params.focusEasing if params.focusEasing
        LYT.render.content.focusDuration parseInt params.focusDuration if params.focusDuration

        # If this section is already playing, don't do anything
        if LYT.player.book? and params.fragment? and
           params.fragment is LYT.player.currentSection().fragment
          return

        log.message "Control: bookPlay: loading book #{params.book}"

        process = LYT.player.load params.book, smilReference, offset, play
        process.done (book) ->
          LYT.render.bookPlayer book, $(page)
          LYT.render.bookIndex book
          LYT.render.bookmarks book

          # See if there are any service announcements every time a new book has been loaded
          LYT.service.getAnnouncements()
          LYT.player.refreshContent()
          LYT.player.setFocus()
          pageTitle = "#{LYT.i18n('Now playing')} #{LYT.player.book.title}"
          LYT.render.setPageTitle pageTitle

          if params.smil? or params.section? or params.offset?
            # When the user selects a 'chapter' or bookmark in #book-index and afterwars open #settings
            # and clicks 'back'-button, the player would go back to the last selected 'chapter' or
            # bookmark.
            # We solve this by updating the hash to only include the params book and from.
            newPath = "book-player?book=#{params.book}" + if params.from? then "&from=#{params.from?}" else ""
            if $.mobile.pushStateEnabled and $.isFunction( window.history.replaceState )
              # Browsers that support pushState, replace the history entry with the new hash,
              # this prevents double entries in our history.
              window.history.replaceState {}, pageTitle, "##{newPath}"
            else
              # Browser without support for pushStat (e.g. IE9) will have to live with
              # the double entry in history.
              window.location.hash = newPath

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
                theme: 'b'
              LYT.render.showDialog($.mobile.activePage, parameters)
        # else just show book player (done by default by the router)

  settings: (type, match, ui, page, event) ->
    params = LYT.router.getParams(match[1])
    promise = LYT.control.ensureLogOn params
    promise.fail -> log.error 'Control: settings: unable to log in'
    promise.done ->
      if type is 'pagebeforeshow'
        if LYT.config.settings.showAdvanced
          $('.advanced-settings').show()
        else
          $('.advanced-settings').hide()

      if type is 'pageshow'
        style = jQuery.extend {}, (LYT.settings.get "textStyle" or {})

        $("#style-settings").find("input").each ->
          el = $(this)
          name = el.attr 'name'
          val = el.val()

          # Setting the GUI
          switch name
            when 'font-size', 'font-family'
              if val is style[name]
                el.attr("checked", true).checkboxradio("refresh")
            when 'marking-color'
              colors = val.split(';')
              if style['background-color'] is colors[0] and style['color'] is colors[1]
                el.attr("checked", true).checkboxradio("refresh")
            when 'playback-rate'
              if Number(val) is LYT.settings.get('playbackRate')
                el.attr("checked", true).checkboxradio("refresh")
            when 'word-highlighting'
              el.prop("checked", LYT.settings.get("wordHighlighting"))
                .checkboxradio("refresh")

  test:  (type, match, ui, page, event) ->
    if type is 'pageshow'
      setTimeout(
        ->
          $(page).trigger 'create'
        100
      )
      LYT.render.hideTestTab()
    else if type is 'pagehide'
      LYT.render.showTestTab()

  defaultPage: -> $.mobile.changePage(LYT.config.defaultPage.hash)
