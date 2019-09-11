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
    #The function getNotaAuthToken() is defined in https://nota.dk/getnotaauthtoken
    if getNotaAuthToken?
      credentials = getNotaAuthToken()
      if credentials.status is 'ok'
        if LYT.config.LYT3?.URL?.includes('{bookid}') and LYT.config.LYT3?.testers?.includes(credentials.username)
          bookid = /book=(\w+)&?/.exec(window.location.href)?[1]

          if bookid and confirm("Fortsæt til test versionen af den nye afspiller?")
            window.location.href = LYT.config.LYT3?.URL.replace '{bookid}', bookid
            return

        log.message 'Session: init: reading credentials from getNotaAuthToken()'
        LYT.session.setCredentials credentials.username, credentials.token
        LYT.service.logOn credentials.username, credentials.token
      else
        log.message 'Session: init: invalid reading credentials from getNotaAuthToken()'
        LYT.service.logOff()
    else
      log.warn 'Session: init: getNotaAuthToken is undefined'

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

