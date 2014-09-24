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
      deferred = deferred.then ->
        # Wait untill the searchterm button is visible
        util.waitForTrue ->
          $('#searchterm').is ':visible'
      deferred = deferred.then ->
        # Perform the search for id=bookId and submit
        $('#searchterm').val "id=#{bookId}"
        $('#search-submit').simulate 'click'

        # Wait for search result by waiting for
        util.waitForTrue ->
          $('#searchresult .book-play-link').length is 1
      deferred = deferred.then ->
        # Load book details by clicking on .book-play-link button
        $('#searchresult .book-play-link').simulate 'click'

        # Wait for player to load
        util.waitForPage 'book-details'
      deferred = deferred.then ->
        # Wait for the render to update the href-attribute on the #details-play-button
        util.waitForTrue ->
          $('#details-play-button').attr('href').indexOf("#book-player?book=#{bookId}") isnt -1
      deferred = deferred.then ->
        # Load book by clicking on #details-play-button button
        $('#details-play-button').simulate 'click'
        util.waitForPage 'book-player'
      # FIXME: It seems that the play button may be active before the book has been loaded. This should be fixed in the player.
      deferred = deferred.then ->
        # Wait for the book to finish loading e.g. for the loader widget to go away
        util.waitForTrue ->
          !$('.ui-loader').is ':visible'
      deferred = deferred.then ->
        util.waitForTrue ->
          LYT.player.book?.id is bookId
    else
      deferred = util.changePage 'book-player'

    deferred

  play = (type) ->
    deferred = load type
    deferred = deferred.then ->
      $('#book-index-button').simulate 'click'
      util.waitForPage 'book-index'
    deferred = deferred.then ->
      $('#NccRootElement li:first div.ui-li a').simulate 'click'
      util.waitForPage 'book-player'
    deferred = deferred.then ->
      util.waitForTrue ->
        !$('.ui-loader').is ':visible'
    deferred = deferred.then ->
      util.waitForTrue ->
        LYT.player.playing

  pause = ->
    deferred = util.changePage 'book-player'
    deferred = deferred.then ->
      $('.lyt-pause').simulate 'click'
    deferred = deferred.then ->
      util.waitForTrue ->
        !LYT.player.playing

  LYT.test.fixtures.book =
    load: load
    play: play
    pause: pause

