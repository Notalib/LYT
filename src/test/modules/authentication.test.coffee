# Requires `/test/fixtures`
# Requires `/test/fixtures/user`
# Requires `/test/fixtures/book`
# Requires `/test/util/mobile.util`
# Requires `/test/util/qunit.chain`

$(document).on 'mobileinit', ->
  fixtures = LYT.test.fixtures
  util = $.mobile.util
  
  QUnit.module 'LYT.feature.authentication'
  asyncTest 'Logging in and out', ->
    console.log 'Start logging in and out test'
    QUnit.Chain fixtures.user.login 'standard'
      .assert 'Login fixture'
      .assert 'Logged in', -> LYT.session.getMemberId()
      .then -> fixtures.user.login 'standard'
      .assert 'Login fixture'
      .assert 'Still logged in', -> LYT.session.getMemberId()
      .then -> fixtures.user.logout()
      .assert 'Logout fixture'
      .assert 'Logged out', -> !LYT.session.getMemberId()
      .always -> QUnit.start()
