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
        return true if Modernizr.autoplayback? and Modernizr.playbackrate? and Modernizr.playbackratelive?

        modernizrDeferred = util.waitForTrue(
          -> Modernizr.autoplayback? and Modernizr.playbackrate? and Modernizr.playbackratelive?
          10
          30000
        )

        LYT.loader.register 'Modernizr tests', modernizrDeferred.promise()

        modernizrDeferred
      .always ->
        QUnit.Chain fixtures.book.play 'standard'
          .assert 'Play fixture'
          .assert 'Player in playing mode', ->
            LYT.player.playing
          .assert 'Audio has src set', ->
            LYT.player.getStatus().src
          .then ->
            util.waitForTrue(
              -> LYT.player.getStatus().currentTime
              10
              5000
            )
          .assert 'Audio has a trueish currentTime'
          .then ->
            if Modernizr.playbackrate
              util.waitForConfirmDialog """
                Afspiller bogen med ønsket hastighed?<br/>
                  - Ved første forsøg, almindelig hastighed.<br/>
                  - Ved andet forsøg dobbelt hastighed.
                """
            else
              false
          .assert 'Initial playbackRate support'
          .always ->
            QUnit.Chain fixtures.book.playbackRate 'standard'
              .assert 'PlaybackRate support'
              .always ->
                QUnit.Chain fixtures.book.pause()
                  .assert 'Player not in playing mode', -> !LYT.player.playing
                  .then -> util.waitForTrue(
                    -> LYT.player.getStatus().paused
                    1
                    500
                  )
                  .assert 'Audio is paused'
                  .always -> QUnit.start()
