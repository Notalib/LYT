# Requires `/common`  
# Requires `/support/lyt/cache`  

# -------------------

# This module keeps track of the user's info and credentials

LYT.session = do ->
  # Username and password
  credentials = null
  
  # Member info (memberId, name, email, etc.)
  memberInfo  = null

  # ## Public API
  
  init: ->
    #The function getNotaAuthToken() is defined in http://wwww.e17.dk/getnotaauthtoken.js
    credentials = getNotaAuthToken()
    if credentials.status is 'ok'
      log.message 'Session: init: reading credentials from getNotaAuthToken()'
      LYT.session.setCredentials credentials.username, credentials.token
  
  getCredentials: -> LYT.cache.read "session", "credentials"
  
  setCredentials: (username, password) ->
    credentials or= {}
    [credentials.username, credentials.password] = [username, password]
    # FIXME: This should respect the automatic log-on option in the user's settings
    LYT.cache.write "session", "credentials", credentials
  
  getInfo: ->
    memberInfo or= LYT.cache.read "session", "memberinfo"
  
  setInfo: (info) ->
    memberInfo or= {}
    jQuery.extend memberInfo, info
    LYT.cache.write "session", "memberinfo", memberInfo
  
  getMemberId: ->
    @getInfo()?.memberId
  
  clear: ->
    credentials = null
    memberInfo  = null
    LYT.cache.remove "session", "credentials"
    LYT.cache.remove "session", "memberinfo"
  
