# Requires `/common`
# Requires `control`
# Requires `player`
# Requires `/view/render`

# -------------------

# This module serves as a router to the rest of the application and contains url entrypoints and event listeners

# -------------------

$(document).ready ->
  LYT.player.init() if not LYT.player.ready
  LYT.render.init()

$(document).bind "mobileinit", ->

  LYT.router = new $.mobile.Router([
    "#book-details([?].*)?":
      handler: "bookDetails"
      events: "bs,s"
    "#book-play([?].*)?":
      handler: "bookPlayer"
      events: "bs,s"
    "#book-index([?].*)?":
      handler: "bookIndex"
      events: "bs,s"
    "#settings":
      handler: "settings"
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
    "#bookshelf":
      handler: "bookshelf"
      events: "s"
   ], LYT.control, { ajaxApp: false }) #defaultHandler: 'bookDetails'
   
  $(LYT.service).bind "logon:rejected", () ->
    # TODO: pass this `redirect` url to the login action somehow
    redirect = window.location.hash
    
    $.mobile.changePage "#login"
  
  $(LYT.service).bind "logoff", ->
    $.mobile.changePage "#login"
  
  $("[data-role=page]").live "pageshow", (event, ui) ->
    _gaq.push [ "_trackPageview", event.target.id ]
  
  $(LYT.service).bind "error:rpc", () ->
    #todo: apologize on behalf of the server 
  
