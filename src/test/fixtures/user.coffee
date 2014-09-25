# Requires `/test/fixtures`
# Requires `/test/util/mobile.util`

$(document).on 'mobileinit', ->
  fixtures = LYT.test.fixtures
  util = $.mobile.util

  login = (type) ->
    username = fixtures.data.users[type].username
    if LYT.session.getMemberId() isnt username
      deferred = util.changePage 'login'
        .then ->
          $('#username').val username
          $('#password').val fixtures.data.users[type].password
          $('#submit').simulate 'click'
        .then -> util.waitForPage 'bookshelf'
        .then ->
          util.waitForClosedLoader()
    else
      deferred = util.changePage 'bookshelf'
        .then ->
          util.waitForClosedLoader()

    deferred

  logout = ->
    deferred = null
    a = null
    if LYT.session.getMemberId()
      deferred = util.changePage 'profile'
        .then -> $('#log-off').simulate 'click'
        .then -> log.message "trigger called (#{deferred.state()})"
        .then -> util.waitForPage 'login'
    else
      deferred = $.Deferred().resolve()

    deferred

  fixtures.user =
    login: login
    logout: logout

