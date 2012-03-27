# Requires `/common`  
# Requires `/support/lyt/cache`  

# -------------------

# This module keeps track of the user's info and credentials

LYT.session = do ->
  # Username and password
  credentials = null
  
  # Member info (memberId, name, email, etc.)
  memberInfo  = null

   # Emit an event
  emit = (event, data = {}) ->
    obj = jQuery.Event event
    delete data.type if data.hasOwnProperty "type"
    jQuery.extend obj, data
    log.message "Session: Emitting #{event} event"
    jQuery(LYT.session).trigger obj
  
  # ## Public API
  
  getCredentials: ->
    credentials or= LYT.cache.read "session", "credentials"
    if credentials is null
      emit "logon:rejected" #emiting a logon event from service...
    else
      return credentials

  
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
  
