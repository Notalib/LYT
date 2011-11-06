# This module handles gui event listeners and utility functions
# work in progress, nothing is really working here

LYT.gui:
  
  goto: "bookshelf"
  
  covercache: (element) ->
    $(element).each ->
      id = $(this).attr("id")
      u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg"
      img = $(new Image()).load(->
        $("#" + id).find("img").attr "src", u
      ).error(->
      ).attr("src", u)

  covercache_one: (element) ->
    id = $(element).find("img").attr("id")
    u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg"
    img = $(new Image()).load(->
      $(element).find("img").attr "src", u
    ).error(->
    ).attr("src", u)
  
  parse_media_name: (mediastring) ->
    unless mediastring.indexOf("AA") is -1
      "Lydbog"
    else
      "Lydbog med tekst"
  
  setup: ->
    $("#login").live "pagebeforeshow", (event) ->
      $("#login-form").submit (event) ->
        @goto = "bookshelf"
        $.mobile.showPageLoadingMsg()
        $("#password").blur()
        event.preventDefault()
        event.stopPropagation()
    
        LYT.settings.set('username') = $("#username").val()  if $("#username").val().length < 10
        LYT.set('password') = $("#password").val()

        LYT.LogOn $("#username").val(), $("#password").val()

    $("#book_index").live "pagebeforeshow", (event) ->
       $("#book_index_content").trigger "create"
           $("li[xhref]").bind "click", (event) ->
             $.mobile.showPageLoadingMsg()
             if ($(window).width() - event.pageX > 40) or (typeof $(this).find("a").attr("href") is "undefined")
                if $(this).find("a").attr("href")
                    event.preventDefault()
                    event.stopPropagation()
                    event.stopImmediatePropagation()
                    #window.fileInterface.GetTextAndSound this
                    $.mobile.changePage "#book-play"
                else
                    event.stopImmediatePropagation()
                    $.mobile.changePage $(this).find("a").attr("href")

    $("#book-play").live "pagebeforeshow", (event) ->
        console.log "afspiller nu - " + isPlayerAlive()
        unless isPlayerAlive()
            @goto = "bookshelf"
            @gotoPage()
        window.app.covercache_one $("#book-middle-menu")
        $("#book-text-content").css "background", @settings.get('markingColor').substring( @settings.get('markingColor').indexOf("-", 0))
        $("#book-text-content").css "color", @settings.get('markingColor').substring( @settings.get('markingColor').indexOf("-", 0) + 1)
        $("#book-text-content").css "font-size",  @settings.get('textSize') + "px"
        $("#book-text-content").css "font-family",  @settings.get('textType')
        $("#bookshelf [data-role=header]").trigger "create"

        $("#book-play").bind "swiperight", ->
            NextPart()

        $("#book-play").bind "swipeleft", ->
            LastPart()

    $("#bookshelf").live "pagebeforeshow", (event) ->
        $.mobile.hidePageLoadingMsg()

    $("#settings").live "pagebeforecreate", (event) ->
        initialize = true
        $("#textarea-example").css "font-size",  @settings.get('textSize') + "px"
        $("#textsize").find("input").val @settings.get('textSize')
        $("#textsize_2").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is  @settings.get('textSize')

        $("#text-types").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is  @settings.get('textType')

        $("#textarea-example").css "font-family", @settings.get('textType')
        $("#marking-color").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is  @settings.get('markingColor')

        $("#textarea-example").css "background", @settings.get('markingColor').substring(0,  @settings.get('markingColor').indexOf("-", 0))
        $("#textarea-example").css "color",  @settings.get('markingColor').substring(0,  @settings.get('markingColor').indexOf("-", 0) + 1)
        $("#textsize_2 input").change ->
            @settings.set('textSize', $(this).attr("value"))

            $("#textarea-example").css "font-size", @settings.get('textSize') + "px"
            $("#book-text-content").css "font-size", @settings.get('textSize') + "px"

        $("#text-types input").change ->
            @settings.set('textType', $(this).attr("value"))

            $("#textarea-example").css "font-family", @settings.get('textType')
            $("#book-text-content").css "font-family", @settings.get('textType')

        $("#marking-color input").change ->
            @settings.set('markingColor', $(this).attr("value"))

            $("#textarea-example").css "background", @settings.get('markingColor').substring(0, @settings.get('markingColor').indexOf("-", 0))
            $("#textarea-example").css "color", @settings.get('markingColor').substring(0, @settings.get('markingColor').indexOf("-", 0) + 1)
            $("#book-text-content").css "background", @settings.get('markingColor').substring(0, @settings.get('markingColor').indexOf("-", 0))
            $("#book-text-content").css "color", @settings.get('markingColor').substring(0, @settings.get('markingColor').indexOf("-", 0) + 1)

        $("#reading-context").click ->
            @settings.set('textPresentation', document.getElementById(@getAttribute("for")).getAttribute("value"))    


