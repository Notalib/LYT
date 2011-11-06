# This module handles gui event listeners, callbacks and various utility functions
# work in progress, nothing is really working here yet

LYT.gui:
  
  next: "bookshelf"
  
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
  
  onBookDetailsSuccess: (data, status) ->
    $("#book-details-image").html "<img id=\"" + data.d[0].imageid + "\" class=\"nota-full\" src=\"/images/default.png\" >"
    s = ""
    s = "<p>Serie: " + data.d[0].series + ", del " + data.d[0].seqno + " af " + data.d[0].totalcnt + "</p>"  if data.d[0].totalcnt > 1
    $("#book-details-content").empty()
    #fixme: remove inline javascript and create new listener for playnewbook
    $("#book-details-content").append("<h2>" + data.d[0].title + "</h2>" + "<h4>" + data.d[0].author + "</h4>" + "<a href=\"javascript:PlayNewBook(" + data.d[0].imageid + ", '" + data.d[0].title.replace("'", "") + "','" + data.d[0].author + "')\" data-role=\"button\" data-inline=\"true\">Afspil</a>" + "<p>" + parse_media_name(data.d[0].media) + "</p>" + "<p>" + data.d[0].teaser + "</p>" + s).trigger "create"
    @covercache_one $("#book-details-image")

  onBookDetailsError: (msg, data) ->
    $("#book-details-image").html "<img src=\"/images/default.png\" >"
    $("#book-details-content").html "<h2>Hov!</h2>" + "<p>Der skulle have været en bog her - men systemet kan ikke finde den. Det beklager vi meget! <a href=\"mailto:info@nota.nu?subject=Bog kunne ikke findes på E17 mobilafspiller\">Send os gerne en mail om fejlen</a>, så skal vi fluks se om det kan rettes.</p>"

  onSearchSuccess: (data, status) ->
    s = ""
    unless data.d[0].resultstatus is "NORESULTS"
      s += "<li><h3>" + data.d[0].totalcount + " resultat(er)</h3></li>"
      $.each data.d, (index, item) ->
        s += "<li id=\"" + item.imageid + "\"><a href=\"#book-details\">" + "<img class=\"ui-li-icon\" src=\"/images/default.png\" /><h3>" + item.title + "</h3><p>" + item.author + " | " + parse_media_name(item.media) + "</p></a></li>"
    else
      s += "<li><h3>Ingen resultater</h3><p>Prøv eventuelt at bruge bredere søgeord. For at teste funktionen, søg på et vanligt navn, såsom \"kim\" eller \"anders\".</p></li>"
      $("#searchresult").html s

  onSearchError = (msg, data) ->
    $("#searchresult").text "Error thrown: " + msg.status

  onSearchComplete: ->
    $("#searchresult").listview "refresh"
    $("#searchresult").find("a:first").css "padding-left", "40px"
    $.mobile.hidePageLoadingMsg()
    @covercache $("#searchresult").html()
  
  setup: ->
    $("#login").live "pagebeforeshow", (event) ->
      $("#login-form").submit (event) ->
        @next = "bookshelf"
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
        unless LYT.player.ready
            @next = "bookshelf"
            @gotoPage()
        @covercache_one $("#book-middle-menu")
        $("#book-text-content").css "background", LYT.settings.get('markingColor').substring( LYT.settings.get('markingColor').indexOf("-", 0))
        $("#book-text-content").css "color", LYT.settings.get('markingColor').substring( LYT.settings.get('markingColor').indexOf("-", 0) + 1)
        $("#book-text-content").css "font-size",  LYT.settings.get('textSize') + "px"
        $("#book-text-content").css "font-family",  LYT.settings.get('textType')
        $("#bookshelf [data-role=header]").trigger "create"

        $("#book-play").bind "swiperight", ->
            NextPart()

        $("#book-play").bind "swipeleft", ->
            LastPart()

    $("#bookshelf").live "pagebeforeshow", (event) ->
        $.mobile.hidePageLoadingMsg()

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
            @settings.set('textType', $(this).attr("value"))

            $("#textarea-example").css "font-family", LYT.settings.get('textType')
            $("#book-text-content").css "font-family", LYT.settings.get('textType')

        $("#marking-color input").change ->
            LYT.settings.set('markingColor', $(this).attr("value"))

            $("#textarea-example").css "background", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#textarea-example").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)
            $("#book-text-content").css "background", vsettings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0))
            $("#book-text-content").css "color", LYT.settings.get('markingColor').substring(0, LYT.settings.get('markingColor').indexOf("-", 0) + 1)


