window.globals =
    text_window: undefined 


initializeGui = ->
    $("#login").live "pagebeforeshow", (event) ->
        $("#login-form").submit (event) ->
            window.app.goto = "bookshelf"
            $.mobile.showPageLoadingMsg()
            $("#password").blur()
            event.preventDefault()
            event.stopPropagation()
            window.app.settings.username = $("#username").val()  if $("#username").val().length < 10
            window.app.settings.password = $("#password").val()
            window.app.SetSettings()
            window.fileInterface.LogOn $("#username").val(), $("#password").val()
    
    $("#book_index").live "pagebeforeshow", (event) ->
        $("#book_index_content").trigger "create"
        $("li[xhref]").bind "click", (event) ->
            $.mobile.showPageLoadingMsg()
            if ($(window).width() - event.pageX > 40) or (typeof $(this).find("a").attr("href") is "undefined")
                if $(this).find("a").attr("href")
                    event.preventDefault()
                    event.stopPropagation()
                    event.stopImmediatePropagation()
                    window.fileInterface.GetTextAndSound this
                    $.mobile.changePage "#book-play"
                else
                    event.stopImmediatePropagation()
                    $.mobile.changePage $(this).find("a").attr("href")

    $("#book-play").live "pagebeforeshow", (event) ->
        console.log "afspiller nu - " + isPlayerAlive()
        unless isPlayerAlive()
            window.app.goto = "bookshelf"
            window.app.gotoPage()
        window.app.covercache_one $("#book-middle-menu")
        $("#book-text-content").css "background", window.app.settings.markingColor.substring(0, window.app.settings.markingColor.indexOf("-", 0))
        $("#book-text-content").css "color", window.app.settings.markingColor.substring( window.app.settings.markingColor.indexOf("-", 0) + 1)
        $("#book-text-content").css "font-size",  window.app.settings.textSize + "px"
        $("#book-text-content").css "font-family",  window.app.settings.textType
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
                success: window.fileInterface.onSearchSuccess
                error: window.fileInterface.onSearchError
                complete: window.fileInterface.onSearchComplete

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
                success: window.fileInterface.onBookDetailsSuccess
                error: window.fileInterface.onBookDetailsError

            false

    $("#bookshelf").live "pagebeforeshow", (event) ->
        $.mobile.hidePageLoadingMsg()

    $("#settings").live "pagebeforecreate", (event) ->
        initialize = true
        $("#textarea-example").css "font-size",  window.app.settings.textSize + "px"
        $("#textsize").find("input").val window.app.settings.textSize
        $("#textsize_2").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is  window.app.settings.textSize

        $("#text-types").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is  window.app.settings.textType

        $("#textarea-example").css "font-family", window.app.settings.textType
        $("#marking-color").find("input").each ->
            $(this).attr "checked", true  if $(this).attr("value") is  window.app.settings.markingColor

        $("#textarea-example").css "background", window.app.settings.markingColor.substring(0,  window.app.settings.markingColor.indexOf("-", 0))
        $("#textarea-example").css "color",  window.app.settings.markingColor.substring( window.app.settings.markingColor.indexOf("-", 0) + 1)
        $("#textsize_2 input").change ->
            window.app.settings.textSize = $(this).attr("value")
            window.app.SetSettings()
            $("#textarea-example").css "font-size", window.app.settings.textSize + "px"
            $("#book-text-content").css "font-size", window.app.settings.textSize + "px"

        $("#text-types input").change ->
            window.app.settings.textType = $(this).attr("value")
            window.app.SetSettings()
            $("#textarea-example").css "font-family", window.app.settings.textType
            $("#book-text-content").css "font-family", window.app.settings.textType

        $("#marking-color input").change ->
            window.app.settings.markingColor = $(this).attr("value")
            window.app.SetSettings()
            $("#textarea-example").css "background", window.app.settings.markingColor.substring(0, window.app.settings.markingColor.indexOf("-", 0))
            $("#textarea-example").css "color", window.app.settings.markingColor.substring(window.app.settings.markingColor.indexOf("-", 0) + 1)
            $("#book-text-content").css "background", window.app.settings.markingColor.substring(0, window.app.settings.markingColor.indexOf("-", 0))
            $("#book-text-content").css "color", window.app.settings.markingColor.substring(window.app.settings.markingColor.indexOf("-", 0) + 1)

        $("#reading-context").click ->
            window.app.settings.textPresentation = document.getElementById(@getAttribute("for")).getAttribute("value")    

$(document).bind "mobileinit", ->
    
    globals.text_window = document.createElement("div")
    
    initializeGui()
    
    window.fileInterface = new window.FileInterface()
    window.app = new window.Application()  
    
    $.mobile.page::options.addBackBtn = true
    window.app.gotoPage() if window.app.GetSettings()  
    
    $("[data-role=page]").live "pageshow", (event, ui) ->
        _gaq.push [ "_setAccount", "UA-25712607-1" ]
        _gaq.push [ "_trackPageview", event.target.id ]
    

