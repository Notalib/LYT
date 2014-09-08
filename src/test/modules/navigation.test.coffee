# Requires `/test/fixtures`
# Requires `/test/fixtures/user`
# Requires `/test/fixtures/book`
# Requires `/test/util/mobile.util`
# Requires `/test/util/qunit.chain`

$(document).on 'mobileinit', ->
  fixtures = LYT.test.fixtures
  util = $.mobile.util
  
  QUnit.module 'LYT.feature.navigation'
  asyncTest 'Changing pages', ->
    console.log 'Changing pages'
    QUnit.Chain util.changePage 'login'
      .assert 'Changed to login page'
      .then -> util.changePage 'support'
      .assert 'Changed to bookshelf page'
      .then -> util.changePage 'support'
      .assert 'Changed to bookshelf page again'
      .always -> QUnit.start()
