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
  searchTerm: null # store last search term
  callback: null #last callback function

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
      events: "s,bs" #
    "#book-play([?].*)?$":
      handler: "bookPlay"
      events: "bs,s"
    "#book-player([?].*)?":
      handler: "bookPlayer"
      events: "s"
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
    "#test":
      handler: "test"
      events: "s,h"
  ], LYT.control, { ajaxApp: false }) #defaultHandler: 'bookDetails'
  
  $.mobile.defaultPageTransition = 'fade'
  
  LYT.router.getBookActionUrl = (bookReference, action = 'book-play', absolute=true) ->
    return null unless bookReference and bookReference.book
    url = "##{action}?book=#{bookReference.book}"
    if bookReference.section
      url += "&section=#{bookReference.section}"
      if bookReference.segment
        url += "&segment=#{bookReference.segment}"
        if bookReference.offset
          url += "&offset=#{bookReference.offset}"
    
    url = if absolute
      if document.baseURI?
        document.baseURI + url
      else
        window.location.hostname + '/' + url 
    else
      url
    
    return url
    
  LYT.router.getSegmentUrl = (segment, offset, action = 'book-play', resolution='segment', absolute=true) ->
    reference = {book: segment.section.nccDocument.book.id}
    unless resolution is 'book'
      reference.section = segment.section.url
      unless resolution is 'section'
        reference.segment = segment.id
        if offset
          reference.offset = offset
          
    return LYT.router.getBookActionUrl reference, action, absolute
 
  # If LYT.service, LYT.session or LYT.catalog emits a logon:rejected, prompt
  # the user to log back in.
  $([LYT.service, LYT.catalog]).bind "logon:rejected", ->
    return if window.location.hash is '#login'
    LYT.service.onCurrentLogOn
      always: ->
        LYT.var.next = window.location.hash #if window.location.hash is "" you came from root
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

  $("[data-role=page]").live "pageshow", (event, ui) ->
    _gaq.push [ "_trackPageview", location.pathname + location.search + location.hash  ]

  #Lyt service error handling (events)    
  
  $(LYT.service).bind "error:rpc", () ->
    #alert "Der er opstået et netværksproblem, prøv at genindlæse siden"
    #TODO: apologize on behalf of the server
  $(LYT.service).bind "error:service", () ->
    #alert "Der er opstået et netværksproblem, prøv at genindlæse siden"

