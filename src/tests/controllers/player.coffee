
asyncTest 'Player starts playing when clicking play', ->
  promise = LYT.bookshelf.load()
  promise.fail (error) ->
    ok(false, 'Got bookshelf')
    start()
  promise.done (books) ->
    ok true, 'Got bookshelf'
    timer = setTimeout(
      ->
        ok false, 'Test timed out'
        start() 
      10000
    )
    $('body').one 'pageshow', (event) ->
      ok event.target.id == 'book-player', 'Loaded book player page.'
      $('#jPlayer').one $.jPlayer.event.play, ->
        clearTimeout(timer);
        start();
      $('.jp-play').trigger('click');

    $.mobile.changePage('#book-player?book=' + books.pop().id);
