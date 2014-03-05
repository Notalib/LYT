# Requires `/common`
# Requires `control`
# Requires `player`
# Requires `/view/render`
# Requires `/support/lyt/gatrack`

# -------------------

# This module serves as a router to the rest of the application and contains url entrypoints and event listeners


#     bc  => pagebeforecreate 1 time event
#     c   => pagecreate 1 time event
#     i   => pageinit
#     bs  => pagebeforeshow
#     s   => pageshow
#     bh  => pagebeforehide
#     h   => pagehide
#     rm  => pageremove

# -------------------

LYT.var =
  next: null # store nextpage

$(document).ready ->
  LYT.session.init()
  LYT.player.init() if not LYT.player.ready
  LYT.render.init()
  LYT.gatrack.init()
  LYT.control.init()

# This is a hack - redirect the first page load to use the real url location
# See http://stackoverflow.com/questions/13086110/jquery-mobile-router-doesnt-route-the-first-page-load
$(document).one 'pagebeforechange', (event, data) -> data.toPage = window.location.hash

$(document).bind "mobileinit", ->
  LYT.router = new $.mobile.Router([
    "#default-page":
      handler: "defaultPage"
      events: "bs"
    "#book-details([?].*)?":
      handler: "bookDetails"
      events: "s,bs"
    "#book-play([?].*)?$": # Deprecated - use book-player in stead
      handler: "bookPlay"
      events: "bs,s"
    "#book-player([?].*)?":
      handler: "bookPlayer"
      events: "bs,s"
    "#book-index([?&].*)?": # Using & because of nested list from jQuery Mobile
      handler: "bookIndex"
      events: "bs"
    "#settings":
      handler: "settings"
      events: "s,bs"
    "#support":
      handler: "support"
      events: "s"
    "#about":
      handler: "about"
      events: "s"
    "#share([?].*)?":
      handler: "share"
      events: "s"
    "#search([?].*)?":
      handler: "search"
      events: "bs,s"
    "#login":
      handler: "login"
      events: "s"
    "#profile":
      handler: "profile"
      events: "s"
    "#bookshelf([?].*)?":
      handler: "bookshelf"
      events: "s"
    "#instrumentation":
      handler: 'instrumentation'
      events: 'bs'
    "#suggestions([?].*)?":
      handler: "suggestions"
      events: "s"
    "#anbefalinger":         # This url is deprecated
      handler: "suggestions"
      events: "s"
    "#guest":                # This url is deprecated, use #bookshelf?guest=true in stead
      handler: "guest"
      events: "s"
    "#redirect":
      handler: "redirect"
      events: "s"
    "#splash-upgrade([?].*)?":
      handler: "splashUpgrade"
      events: "bs"
    "#test":
      handler: "test"
      events: "s,h"
  ], LYT.control, { ajaxApp: false, debugHandler: (err) -> throw err })

  $.mobile.defaultPageTransition = 'fade'

  # Generate an url for a point in a book given:
  # - bookReference: an object with the following properties:
  #    - book:       id of book
  #    - section:    section in book (optional)
  #    - segment:    id of par element in section (optional)
  #    - offset: time offset relative to start of par element in section (optional)
  # - action: what action to use in the url (defaults to 'book-player')
  # - absolute: boolean indicating if the url should be absolute or relative
  LYT.router.getBookActionUrl = (bookReference, action = 'book-player', absolute=true) ->
    return null unless bookReference?.book?
    url = "##{action}?book=#{bookReference.book}"
    if bookReference.smil or bookReference.section
      url += "&smil=#{bookReference.smil or bookReference.section}"
      if bookReference.segment
        url += "&segment=#{bookReference.segment}"
        if bookReference.offset
          offset = bookReference.offset

          # If we've got an unformatted number (in seconds instead of hh:mm:ss),
          # we need to format it
          if not isNaN offset
            offset = LYT.utils.formatTime offset
          url += "&offset=#{offset}"

    url = if absolute
      if document.baseURI?
        document.baseURI + url
      else
        window.location.protocol + "//" + window.location.hostname + window.location.pathname + url
    else
      url

    return url

  # If LYT.service, LYT.session or LYT.catalog emits a logon:rejected, prompt
  # the user to log back in.
  $([LYT.service, LYT.catalog]).bind "logon:rejected", ->
    return if window.location.hash is '#login'
    LYT.service.onCurrentLogOn
      always: ->
        LYT.var.next = window.location.hash # If window.location.hash is "" you came from root
        params = LYT.router.getParams window.location.hash
        if params?.guest?
          promise = LYT.service.logOn LYT.config.service.guestUser, LYT.config.service.guestLogin
          promise.done -> $.mobile.changePage LYT.var.next
          promise.fail -> $.mobile.changePage "#login"
        else
          $.mobile.changePage "#login"

  $(LYT.service).bind "logoff", ->
    LYT.player.stop()
    $.mobile.changePage "#login"

  $(document).on "pageshow", "[data-role=page]", (event, ui) ->
    _gaq.push [ "_trackPageview", location.pathname + location.search + location.hash  ]

  #Lyt service error handling (events)

  $(LYT.service).bind "error:rpc", () ->
    #alert "Der er opstået et netværksproblem, prøv at genindlæse siden"
    #TODO: apologize on behalf of the server
  $(LYT.service).bind "error:service", () ->
    #alert "Der er opstået et netværksproblem, prøv at genindlæse siden"

