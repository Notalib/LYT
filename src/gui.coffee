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
    
        @settings.set('username') = $("#username").val()  if $("#username").val().length < 10
        @settings.set('password') = $("#password").val()

        @protocol.LogOn $("#username").val(), $("#password").val()

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

    $("#search").live "pagebeforeshow", (event) ->
        $("#search-form").submit ->
            $("#searchterm").blur()
            $.mobile.showPageLoadingMsg()
            $("#searchresult").empty()
            $.ajax
                type: "POST"
                contentType: "application/json; charset=utf-8"
                dataType: "json"
                url: "/Lyt/search.asmx/SearchFreetext"
                cache: false
                data: "{term:\"" + $("#searchterm").val() + "\"}"
                success: #fixme window.fileInterface.onSearchSuccess
                error: #fixme window.fileInterface.onSearchError
                complete: #fixme window.fileInterface.onSearchComplete

            false

        $("#searchterm").autocomplete
            source: (request, response) ->
                $.ajax
                    url: "/Lyt/search.asmx/SearchAutocomplete"
                    data: "{term:\"" + $("#searchterm").val() + "\"}"
                    dataType: "json"
                    type: "POST"
                    contentType: "application/json; charset=utf-8"
                    dataFilter: (data) ->
                        data

                    success: (data) ->
                        response $.map(data.d, (item) ->
                            value: item.keywords
                        )
                        $(".ui-autocomplete").css "visibility", "hidden"
                        list = $(".ui-autocomplete").find("li").each(->
                            $(this).removeAttr "class"
                            $(this).attr "class", "ui-icon-searchfield"
                            $(this).removeAttr "role"
                            $(this).html "<h3>" + $(this).find("a").text() + "</h3>"
                            $(this).attr "onclick", "javascript:$(\"#searchterm\").val('" + $(this).text() + "')"
                        )

                        $(list).html "<h3>Ingen forslag</h3>"  if list.length is 1 and $(list).find("h3:first").text().length is 0
                        $("#searchresult").html(list).listview "refresh"

                    error: (XMLHttpRequest, textStatus, errorThrown) ->
                        alert textStatus

            minLength: 2

        $("#searchterm").bind "autocompleteclose", (event, ui) ->
            $("#search-form").submit()

        $("#search li").live "click", ->
            $("#book-details-image").empty()
            $("#book-details-content").empty()
            $.ajax
                type: "POST"
                contentType: "application/json; charset=utf-8"
                dataType: "json"
                url: "/Lyt/search.asmx/GetItemById"
                cache: false
                data: "{itemid:\"" + $(this).attr("id") + "\"}"
                success: #fixme: window.fileInterface.onBookDetailsSuccess
                error: #fixme: window.fileInterface.onBookDetailsError

            false

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


