asyncTest 'Player starts playing when clicking play', ->
  cleanupHandlers = []
  cleanup = ->
    handler() for handler in cleanupHandlers
    start()

  # Set up a timeout handler that will cause the test to time out if something
  # goes wrong
  timer = setTimeout(
    ->
      ok false, 'Test timed out'
      cleanup()
    10000
  )
  cleanupHandlers.push -> clearTimeout timer

  # Get some items from the bookshelf
  promise = LYT.bookshelf.load()
  promise.fail (error) ->
    ok(false, 'Got bookshelf')
    cleanup()

  promise.done (books) ->
    ok true, 'Got bookshelf'

    # Set up a handler that is called when the book starts playing    
    pageHandler = (event) ->
      ok event.target.id == 'book-player', 'Loaded book player page'
      playHandler = ->
        ok true, 'Player started playing'
        cleanup()
      $('#jplayer').one $.jPlayer.event.play, playHandler
      cleanupHandlers.push -> $('#jplayer').off $.jPlayer.event.play, playHandler

      $('.jp-play').trigger 'click'
      
    $('body').one 'pageshow', pageHandler
    cleanupHandlers.push -> $('body').off 'pageshow', pageHandler

    # Now play the book
    $.mobile.changePage('#book-player?book=' + books.pop().id);
