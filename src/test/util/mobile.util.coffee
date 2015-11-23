do (jQuery) ->
  $ = jQuery

  isLoaderVisible = -> $('.ui-loader').is ':visible'

  activePage = ->
    $activePage = $.mobile.activePage
    if $activePage and $activePage.attr( 'id' ) isnt '#default-page'
      if $activePage.is(':visible') and Number($activePage.css( 'opacity' )) is 1 and not isLoaderVisible()
        return $activePage.attr 'id'

  timeoutDeferred = (timeout) ->
    deferred = $.Deferred()
    setTimeout(
      -> deferred.reject("timeout: exceeded #{timeout} ms")
      timeout
    )
    deferred

  changePage = (page, timeout = 10000) ->
    deferred = waitForPage page, timeout
    if deferred.state() is 'pending'
      $.mobile.changePage '#' + page
    deferred

  waitForTrue = (callback, interval = 100, timeout = 10000) ->
    deferred = timeoutDeferred timeout
    intervalHandle = setInterval(
      -> deferred.resolve() if callback()
      interval
    )
    deferred.always -> clearInterval intervalHandle
    deferred

  waitForPage = (page, timeout = 10000) ->
    deferred = null
    if activePage() is page
      deferred = $.Deferred().resolve()
    else
      deferred = pageShowDeferred()
      deferred.progress (activePage) ->
        if activePage is page
          deferred.resolve()
    return deferred

  waitForConfirmDialog = (msg) ->
    deferred = $.Deferred()

    testDialog = $('#test-dialog')
    testDialog.find('.test-dialog-msg').html(msg)

    buttonsContainer = testDialog.find('.test-dialog-buttons')
    buttonsContainer.empty()

    yesBtn = $("<a href='#{window.location.hash or '#'}' data-role='button' data-rel='back' data-theme='b'>#{LYT.l10n.get('Yes')}</a>")
    noBtn = $("<a href='#{window.location.hash or '#'}' data-role='button' data-rel='back' data-theme='c'>#{LYT.l10n.get('No')}</a>")
    buttonsContainer
      .append(yesBtn)
      .append(noBtn)

    yesBtn.on 'click', ->
      deferred.resolve()

    noBtn.on 'click', ->
      deferred.reject()

    $.mobile.changePage '#test-dialog'

    deferred

  waitForClosedLoader = (interval = 100, timeout = 10000) ->
    waitForTrue(
      -> !isLoaderVisible()
      interval
      timeout
    )

  pingDeferred = (timeout = 10000, interval = 100) ->
    deferred = timeoutDeferred timeout
    intervalHandle = setInterval(
      -> deferred.notify()
      interval
    )
    deferred.always -> clearInterval intervalHandle

  pageShowDeferred = (timeout = 10000) ->
    deferred = $.Deferred()

    lastPage = null
    pingHandler = ->
      if activePage() isnt lastPage
        lastPage = activePage()
        deferred.notify lastPage

    pingDeferred()
     .fail (error) -> deferred.reject error
     .progress pingHandler

    pingHandler()

    deferred

  $(document).on 'mobileinit', ->
    $.mobile.util =
      timeoutDeferred: timeoutDeferred
      changePage: changePage
      waitForTrue: waitForTrue
      waitForPage: waitForPage
      pageShowDeferred: pageShowDeferred
      activePage: activePage
      waitForClosedLoader: waitForClosedLoader
      waitForConfirmDialog: waitForConfirmDialog
