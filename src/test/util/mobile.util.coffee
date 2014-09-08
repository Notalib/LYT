do (jQuery) ->
  $ = jQuery

  activePage = ->
    $activePage = $.mobile.activePage
    if $activePage
      if $activePage.is(':visible')
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
