# This module serves as a router to the rest of the application and contains url entrypoints and event listeners

$(document).ready ->
  LYT.player.setup()

$(document).bind "mobileinit", ->
  
  $(LYT.service).bind "logon:rejected", () ->
    $.mobile.changePage "#login"
  
  $(LYT.service).bind "error:rpc", () ->
    #$.mobile.changePage "#login"  
  
  $(document).bind "pagebeforechange", (e, data) ->
      # Intercept and parse urls with a query string
      # As done here http://jquerymobile.com/test/docs/pages/page-dynamic.html
      if typeof data.toPage is "string"
        u = $.mobile.path.parseUrl(data.toPage)
        if u.hash.search(/^#book-details/) isnt -1
          LYT.app.bookDetails u, data.options
          e.preventDefault()
        else if u.hash.search(/^#book-play/) isnt -1
          LYT.app.bookPlayer u, data.options
          e.preventDefault()
        else if u.hash.search(/^#book-index/) isnt -1
          log.message "Main: changepage"
          LYT.app.bookIndex u, data.options
          e.preventDefault()

  $("#login").live "pagebeforeshow", (event) ->
      $("#login-form").submit (event) ->

        $.mobile.showPageLoadingMsg()
        $("#password").blur()

        LYT.service.logOn($("#username").val(), $("#password").val())
          .done ->
            $.mobile.changePage "#bookshelf"

          .fail ->
            log.message "log on failure"

        event.preventDefault()
        event.stopPropagation()

  $("#bookshelf").live "pagebeforeshow", (event) ->
    LYT.app.bookshelf()

  $("#settings").live "pagebeforecreate", (event) ->
        initialize = true
        $("#textarea-example").css "font-size",  LYT.settings.get('textSize') + "px"
        $("#textsize").find("input").val LYT.settings.get('textSize')
        $("#textsize_2").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('textSize')

        $("#text-types").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('textType')

        $("#textarea-example").css "font-family", LYT.settings.get('textType')
        $("#marking-color").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is LYT.settings.get('markingColor')

        $("#textarea-example").css "background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
        $("#textarea-example").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
        $("#textsize_2 input").change ->
            LYT.settings.set('textSize', $(this).attr("value"))

            $("#textarea-example").css "font-size", LYT.settings.get('textSize') + "px"
            $("#book-text-content").css "font-size", LYT.settings.get('textSize') + "px"

        $("#text-types input").change ->
            LYT.settings.set('textType', $(this).attr("value"))

            $("#textarea-example").css "font-family", LYT.settings.get('textType')
            $("#book-text-content").css "font-family", LYT.settings.get('textType')

        $("#marking-color input").change ->
            LYT.settings.set('markingColor', $(this).attr("value"))

            $("#textarea-example").css "background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#textarea-example").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
            $("#book-text-content").css "background", vsettings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#book-text-content").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)

  $("[data-role=page]").live "pageshow", (event, ui) ->
        _gaq.push [ "_trackPageview", event.target.id ]