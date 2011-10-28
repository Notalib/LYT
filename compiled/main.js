(function() {
  var initializeGui;
  window.globals = {
    text_window: void 0
  };
  initializeGui = function() {
    $("#login").live("pagebeforeshow", function(event) {
      return $("#login-form").submit(function(event) {
        window.app.goto = "bookshelf";
        $.mobile.showPageLoadingMsg();
        $("#password").blur();
        event.preventDefault();
        event.stopPropagation();
        if ($("#username").val().length < 10) {
          window.app.settings.username = $("#username").val();
        }
        window.app.settings.password = $("#password").val();
        window.app.SetSettings();
        return window.fileInterface.LogOn($("#username").val(), $("#password").val());
      });
    });
    $("#book_index").live("pagebeforeshow", function(event) {
      $("#book_index_content").trigger("create");
      return $("li[xhref]").bind("click", function(event) {
        $.mobile.showPageLoadingMsg();
        if (($(window).width() - event.pageX > 40) || (typeof $(this).find("a").attr("href") === "undefined")) {
          if ($(this).find("a").attr("href")) {
            event.preventDefault();
            event.stopPropagation();
            event.stopImmediatePropagation();
            window.fileInterface.GetTextAndSound(this);
            return $.mobile.changePage("#book-play");
          } else {
            event.stopImmediatePropagation();
            return $.mobile.changePage($(this).find("a").attr("href"));
          }
        }
      });
    });
    $("#book-play").live("pagebeforeshow", function(event) {
      console.log("afspiller nu - " + isPlayerAlive());
      if (!isPlayerAlive()) {
        window.app.goto = "bookshelf";
        window.app.gotoPage();
      }
      window.app.covercache_one($("#book-middle-menu"));
      $("#book-text-content").css("background", window.app.settings.markingColor.substring(0, window.app.settings.markingColor.indexOf("-", 0)));
      $("#book-text-content").css("color", window.app.settings.markingColor.substring(window.app.settings.markingColor.indexOf("-", 0) + 1));
      $("#book-text-content").css("font-size", window.app.settings.textSize + "px");
      $("#book-text-content").css("font-family", window.app.settings.textType);
      $("#bookshelf [data-role=header]").trigger("create");
      $("#book-play").bind("swiperight", function() {
        return NextPart();
      });
      return $("#book-play").bind("swipeleft", function() {
        return LastPart();
      });
    });
    $("#search").live("pagebeforeshow", function(event) {
      $("#search-form").submit(function() {
        $("#searchterm").blur();
        $.mobile.showPageLoadingMsg();
        $("#searchresult").empty();
        $.ajax({
          type: "POST",
          contentType: "application/json; charset=utf-8",
          dataType: "json",
          url: "/Lyt/search.asmx/SearchFreetext",
          cache: false,
          data: "{term:\"" + $("#searchterm").val() + "\"}",
          success: window.fileInterface.onSearchSuccess,
          error: window.fileInterface.onSearchError,
          complete: window.fileInterface.onSearchComplete
        });
        return false;
      });
      $("#searchterm").autocomplete({
        source: function(request, response) {
          return $.ajax({
            url: "/Lyt/search.asmx/SearchAutocomplete",
            data: "{term:\"" + $("#searchterm").val() + "\"}",
            dataType: "json",
            type: "POST",
            contentType: "application/json; charset=utf-8",
            dataFilter: function(data) {
              return data;
            },
            success: function(data) {
              var list;
              response($.map(data.d, function(item) {
                return {
                  value: item.keywords
                };
              }));
              $(".ui-autocomplete").css("visibility", "hidden");
              list = $(".ui-autocomplete").find("li").each(function() {
                $(this).removeAttr("class");
                $(this).attr("class", "ui-icon-searchfield");
                $(this).removeAttr("role");
                $(this).html("<h3>" + $(this).find("a").text() + "</h3>");
                return $(this).attr("onclick", "javascript:$(\"#searchterm\").val('" + $(this).text() + "')");
              });
              if (list.length === 1 && $(list).find("h3:first").text().length === 0) {
                $(list).html("<h3>Ingen forslag</h3>");
              }
              return $("#searchresult").html(list).listview("refresh");
            },
            error: function(XMLHttpRequest, textStatus, errorThrown) {
              return alert(textStatus);
            }
          });
        },
        minLength: 2
      });
      $("#searchterm").bind("autocompleteclose", function(event, ui) {
        return $("#search-form").submit();
      });
      return $("#search li").live("click", function() {
        $("#book-details-image").empty();
        $("#book-details-content").empty();
        $.ajax({
          type: "POST",
          contentType: "application/json; charset=utf-8",
          dataType: "json",
          url: "/Lyt/search.asmx/GetItemById",
          cache: false,
          data: "{itemid:\"" + $(this).attr("id") + "\"}",
          success: window.fileInterface.onBookDetailsSuccess,
          error: window.fileInterface.onBookDetailsError
        });
        return false;
      });
    });
    $("#bookshelf").live("pagebeforeshow", function(event) {
      return $.mobile.hidePageLoadingMsg();
    });
    return $("#settings").live("pagebeforecreate", function(event) {
      var initialize;
      initialize = true;
      $("#textarea-example").css("font-size", window.app.settings.textSize + "px");
      $("#textsize").find("input").val(window.app.settings.textSize);
      $("#textsize_2").find("input").each(function() {
        if ($(this).attr("value") === window.app.settings.textSize) {
          return $(this).attr("checked", true);
        }
      });
      $("#text-types").find("input").each(function() {
        if ($(this).attr("value") === window.app.settings.textType) {
          return $(this).attr("checked", true);
        }
      });
      $("#textarea-example").css("font-family", window.app.settings.textType);
      $("#marking-color").find("input").each(function() {
        if ($(this).attr("value") === window.app.settings.markingColor) {
          return $(this).attr("checked", true);
        }
      });
      $("#textarea-example").css("background", window.app.settings.markingColor.substring(0, window.app.settings.markingColor.indexOf("-", 0)));
      $("#textarea-example").css("color", window.app.settings.markingColor.substring(window.app.settings.markingColor.indexOf("-", 0) + 1));
      $("#textsize_2 input").change(function() {
        window.app.settings.textSize = $(this).attr("value");
        window.app.SetSettings();
        $("#textarea-example").css("font-size", window.app.settings.textSize + "px");
        return $("#book-text-content").css("font-size", window.app.settings.textSize + "px");
      });
      $("#text-types input").change(function() {
        window.app.settings.textType = $(this).attr("value");
        window.app.SetSettings();
        $("#textarea-example").css("font-family", window.app.settings.textType);
        return $("#book-text-content").css("font-family", window.app.settings.textType);
      });
      $("#marking-color input").change(function() {
        window.app.settings.markingColor = $(this).attr("value");
        window.app.SetSettings();
        $("#textarea-example").css("background", window.app.settings.markingColor.substring(0, window.app.settings.markingColor.indexOf("-", 0)));
        $("#textarea-example").css("color", window.app.settings.markingColor.substring(window.app.settings.markingColor.indexOf("-", 0) + 1));
        $("#book-text-content").css("background", window.app.settings.markingColor.substring(0, window.app.settings.markingColor.indexOf("-", 0)));
        return $("#book-text-content").css("color", window.app.settings.markingColor.substring(window.app.settings.markingColor.indexOf("-", 0) + 1));
      });
      return $("#reading-context").click(function() {
        return window.app.settings.textPresentation = document.getElementById(this.getAttribute("for")).getAttribute("value");
      });
    });
  };
  $(document).bind("mobileinit", function() {
    globals.text_window = document.createElement("div");
    initializeGui();
    window.fileInterface = new window.FileInterface();
    window.app = new window.Application();
    $.mobile.page.prototype.options.addBackBtn = true;
    if (window.app.GetSettings()) {
      window.app.gotoPage();
    }
    return $("[data-role=page]").live("pageshow", function(event, ui) {
      _gaq.push(["_setAccount", "UA-25712607-1"]);
      return _gaq.push(["_trackPageview", event.target.id]);
    });
  });
}).call(this);
