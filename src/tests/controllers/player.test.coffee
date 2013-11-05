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
    15000
  )
  cleanupHandlers.push -> clearTimeout timer

  # Get some items from the bookshelf
  promise = LYT.bookshelf.load()
  promise.fail (error) ->
    ok(false, 'Got bookshelf')
    cleanup()

  promise.done (books) ->
    ok true, 'Got bookshelf'

    bookId = books.shift().id

    # Set up a handler that is called when the player is ready
    pageHandler = (event) ->
      ok event.target.id == 'book-player', 'Loaded book player page'
      bail = false
      promise = LYT.player.load bookId
      promise.fail (error) ->
        return if bail
        ok false, 'Loading book'
        cleanup()
      promise.done ->
        return if bail
        ok not LYT.player.playing, 'Player has playing flag to off when book has been loaded'
        loadstartHandler = ->
          ok not LYT.player.playing, 'Player has playing flag to off at loadstart event'
          playHandler = ->
            ok LYT.player.playing, 'Player has set playing flag at play event'
            setTimeout(
              ->
                ok LYT.player.playing, 'Player has set playing flag 1 second after play event'
                ok not LYT.player.getStatus().paused, 'jPlayer is playing'
                cleanup()
              1000
            )
          $('#jplayer').one $.jPlayer.event.play, playHandler
          cleanupHandlers.push -> $('#jplayer').off $.jPlayer.event.play, playHandler

          setTimeout(
            ->
              log.message 'Test: player starts playing when clicking play: clicking play button'
              $('.lyt-play').trigger 'click'
            2000
          )

        $('#jplayer').one $.jPlayer.event.loadstart, loadstartHandler
        cleanupHandlers.push -> $('#jplayer').off $.jPlayer.event.loadstart, loadstartHandler

      cleanupHandlers.push -> bail = true

    $('body').one 'pageshow', pageHandler
    cleanupHandlers.push -> $('body').off 'pageshow', pageHandler

    # Now play the book
    $.mobile.changePage '#book-player?book=' + bookId
