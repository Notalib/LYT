# Requires `/test/fixtures`
# Requires `/test/util/mobile.util`

$(document).on 'mobileinit', ->
  fixtures = LYT.test.fixtures
  util = $.mobile.util

  load = (type) ->
    bookId = fixtures.data.books[type].id

    if LYT.player.book?.id isnt bookId
      deferred = util.changePage 'search'
      deferred = deferred.then ->
        util.waitForTrue ->
          $('#searchterm').is ':visible'
      deferred = deferred.then ->
        $('#searchterm').val "id=#{bookId}"
        $('#search-submit').simulate 'click'
        util.waitForTrue ->
          $('#searchresult .book-play-link').length is 1
      deferred = deferred.then ->
        $('#searchresult .book-play-link').simulate 'click'
        util.waitForPage 'book-details'
      deferred = deferred.then ->
        util.waitForTrue ->
          $('#details-play-button').attr('href').indexOf("#book-player?book=#{bookId}") isnt -1
      deferred = deferred.then ->
        $('#details-play-button').simulate 'click'
        util.waitForPage 'book-player'
      # FIXME: It seems that the play button may be active before the book has been loaded. This should be fixed in the player.
      deferred = deferred.then ->
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

