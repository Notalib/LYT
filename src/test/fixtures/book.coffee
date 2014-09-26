# Requires `/test/fixtures`
# Requires `/test/util/mobile.util`

$(document).on 'mobileinit', ->
  fixtures = LYT.test.fixtures
  util = $.mobile.util

  load = (type) ->
    bookId = fixtures.data.books[type].id

    if LYT.player.book?.id isnt bookId
      # Go to search page
      deferred = util.changePage 'search'
        .then ->
          # Wait untill the searchterm button is visible
          util.waitForTrue ->
            $('#searchterm').is ':visible'
        .then ->
          # Perform the search for id=bookId and submit
          $('#searchterm').val "id=#{bookId}"
          $('#search-submit').simulate 'click'

          # Wait for search result by waiting for
          util.waitForTrue -> $('#searchresult .book-play-link').length is 1
        .then ->
          # Load book details by clicking on .book-play-link button
          $('#searchresult .book-play-link').simulate 'click'

          # Wait for player to load
          util.waitForPage 'book-details'
        .then ->
          # Wait for the render to update the href-attribute on the #details-play-button
          util.waitForTrue ->
            $('#details-play-button').attr('href').indexOf("#book-player?book=#{bookId}") isnt -1
        .then ->
          # Load book by clicking on #details-play-button button
          $('#details-play-button').simulate 'click'
          util.waitForPage 'book-player'
    else
      deferred = util.changePage 'book-player'

    deferred
      # FIXME: It seems that the play button may be active before the book has been loaded. This should be fixed in the player.
      .then ->
        # Wait for the book to finish loading e.g. for the loader widget to go away
        util.waitForClosedLoader()
      .then ->
        util.waitForTrue -> LYT.player.book?.id is bookId
      .then ->
        util.waitForTrue -> LYT.render.isPlayerNavigationEnabled()
      .then ->
        if LYT.player.playClickHook
          $('.lyt-play').one 'click', ->
            deferred.resolve()

          alert 'Click play'
          deferred
            .then ->
              util.waitForTrue(
                -> LYT.player.playing
                100
                30000
              )
            .then ->
              util.waitForTrue -> LYT.player.currentSegment
            .then ->
              util.waitForClosedLoader()
        else
          true

  play = (type) ->
    deferred = load type
      .then ->
        $('#book-index-button').simulate 'click'
        util.waitForPage 'book-index'
      .then ->
        $('#NccRootElement li:first div.ui-li a').simulate 'click'
        util.waitForPage 'book-player'
      .then ->
        util.waitForClosedLoader()
      .then ->
        util.waitForTrue ->
          LYT.player.playing

  playbackRate = (type) ->
    deferred = load type
      .then ->
        $('#book-settings-button').simulate 'click'
        util.waitForPage 'settings'
      .then ->
        util.waitForTrue -> Modernizr.playbackrate?
      .then ->
        unless (Modernizr.playbackrate?)
          deferred.reject()
      .then ->
        $('#settings #playback-rate-5').simulate 'click'
        $('#settings .ui-header a:first').simulate 'click'
        util.waitForPage 'book-player'
      .then ->
        util.waitForConfirmDialog "Afspiller bogen med dobbelt hastighed?"

  pause = ->
    deferred = util.changePage 'book-player'
      .then ->
        $('.lyt-pause').simulate 'click'
      .then ->
        util.waitForTrue -> !LYT.player.playing

  LYT.test.fixtures.book =
    load: load
    play: play
    pause: pause
    playbackRate: playbackRate

