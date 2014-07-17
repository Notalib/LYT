# Requires `/common`
# Requires `/support/lyt/store`

# -------------------

# This module keeps track of the user's info and credentials

LYT.session = do ->
  # Username and password
  credentials = null

  # Member info (memberId, name, email, etc.)
  memberInfo = null

  # Settings
  settings = null

  # ## Public API

  init: ->
    #The function getNotaAuthToken() is defined in http://wwww.e17.dk/getnotaauthtoken.js
    if getNotaAuthToken?
      credentials = getNotaAuthToken()
      if credentials.status is 'ok'
        log.message 'Session: init: reading credentials from getNotaAuthToken()'
        LYT.session.setCredentials credentials.username, credentials.token
    else
      log.warn 'Session: init: getNotaAuthToken is undefined'

  getCredentials: ->
    credentials or= JSON.parse LYT.store.read("session/credentials") or "{}"

  setCredentials: (username, password) ->
    credentials or= {}
    [credentials.username, credentials.password] = [username, password]
    # FIXME: This should respect the automatic log-on option in the user's settings
    LYT.store.write "session/credentials", credentials

  settings: () ->
    id = @getMemberId()
    if not settings? or id isnt settings.memberID
      settings = new LYT.Settings id

    settings

  getInfo: ->
    memberInfo or= JSON.parse LYT.store.read "session/memberinfo"

  setInfo: (info) ->
    memberInfo or= {}
    jQuery.extend memberInfo, info
    LYT.store.write "session/memberinfo", memberInfo

  getMemberId: ->
    @getInfo()?.memberId

  clear: ->
    credentials = null
    memberInfo = null
    settings = null
    LYT.store.remove "session/credentials"
    LYT.store.remove "session/memberinfo"

