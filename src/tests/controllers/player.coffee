asyncTest 'Player starts playing when clicking play', ->
  cleanupHandlers = []
  cleanup = ->
    handler() for handler in cleanupHandlers
    start()

  promise = LYT.bookshelf.load()
  promise.fail (error) ->
    ok(false, 'Got bookshelf')
    cleanup()

  promise.done (books) ->
    ok true, 'Got bookshelf'
    timer = setTimeout(
      ->
        ok false, 'Test timed out'
        cleanup()
      10000
    )
    cleanupHandlers.push -> clearTimeout timer
    
    pageHandler = (event) ->
      ok event.target.id == 'book-player', 'Loaded book player page.'
      playHandler = -> cleanup()
      $('#jPlayer').one $.jPlayer.event.play, playHandler
      cleanupHandlers.push -> $('#jPlayer').off $.jPlayer.event.play, playHandler

      $('.jp-play').trigger 'click'
      
    $('body').one 'pageshow', pageHandler
    cleanupHandlers.push -> $('body').off 'pageshow', pageHandler

    $.mobile.changePage('#book-player?book=' + books.pop().id);
