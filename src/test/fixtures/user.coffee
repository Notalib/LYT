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
          $('#submit').trigger 'click'
        .then -> util.waitForPage 'bookshelf'
    else
      deferred = util.changePage 'bookshelf'
  
    deferred
  
  logout = ->
    deferred = null
    a = null
    if LYT.session.getMemberId()
      deferred = util.changePage 'profile'
        .then -> $('#log-off').trigger 'click'
        .then -> console.log "trigger called (#{deferred.state()})"
        .then -> util.waitForPage 'login'
    else
      deferred = $.Deferred().resolve()
  
    deferred
  
  fixtures.user =
    login: login
    logout: logout
  
