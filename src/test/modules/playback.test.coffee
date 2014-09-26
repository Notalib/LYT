# Requires `/test/fixtures`
# Requires `/test/fixtures/user`
# Requires `/test/fixtures/book`
# Requires `/test/util/mobile.util`
# Requires `/test/util/qunit.chain`

$(document).on 'mobileinit', ->
  fixtures = LYT.test.fixtures
  util = $.mobile.util

  QUnit.module 'LYT.feature.playback'
  asyncTest 'Playing a book', ->
    QUnit.Chain fixtures.user.login 'standard'
      .assert 'Login fixture'
      .then ->
        util.waitForTrue(
          ->
            res = Modernizr.autoplayback? and Modernizr.playbackrate? and Modernizr.playbackratelive?
            console.log 'Modernizr tests done', res

            res
        )
      .assert 'Modernizr tests done'
      .then ->
        fixtures.book.play 'standard'
      .assert 'Play fixture'
      .assert 'Player in playing mode', ->
        LYT.player.playing
      .assert 'Audio has src set', ->
        LYT.player.getStatus().src
      # FIXME: for some reason, the audio object may claim it is paused even when playing?!
      # .assert 'Audio is not paused', -> !LYT.player.getStatus().paused
      .assert 'Audio has a trueish currentTime', ->
        util.waitForTrue(
          -> LYT.player.getStatus().currentTime
          100
        )
      .then ->
        util.waitForConfirmDialog "Afspiller bogen med ønsket hastighed?<br/>Ved første forsøg, almindelig hastighed, ved andet forsøg dobbelt hastighed."
      .assert 'Initial playbackRate support'
      .then -> fixtures.book.playbackRate 'standard'
      .assert 'PlaybackRate support'
      .always -> fixtures.book.pause()
      .assert 'Player not in playing mode', -> !LYT.player.playing
      .assert 'Audio is paused', -> LYT.player.getStatus().paused
      .always -> QUnit.start()
