(function() {
  var Application;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Application = (function() {
    var onSearchError;
    function Application() {
      this.setDestination = __bind(this.setDestination, this);;
      this.eventSystemGotBookShelf = __bind(this.eventSystemGotBookShelf, this);;
    }
    Application.prototype.PROTOCOL_TYPE = "DODP";
    Application.prototype.settings = void 0;
    Application.prototype.book_tree = void 0;
    Application.prototype.goto = "bookshelf";
    Application.prototype.full_bookshelf = "";
    Application.prototype.bookshelf_showitems = 5;
    Application.prototype.nowPlayingIcon = true;
    Application.prototype.GetSettings = function() {
      if (!this.supports_local_storage()) {
        alert("Din browser understøtter desværre ikke LYT, da vi ikke må få lov at gemme lokale filer på din telefon eller computer");
        return false;
      } else {
        try {
          this.settings = localStorage.getItem("mobileSettings");
          if (!(this.settings != null) || this.settings === "undefined") {
            this.InitSettings();
            return false;
          } else {
            this.settings = JSON.parse(localStorage.getItem("mobileSettings"));
            if (this.settings.version !== "dev5.8" || this.settings.username === -1 || this.settings.username === "") {
              this.InitSettings();
              return false;
            }
          }
        } catch (e) {
          alert(e.message);
          return false;
        }
      }
      return true;
    };
    Application.prototype.InitSettings = function() {
      window.fileInterface.LogOff();
      localStorage.clear();
      this.settings = {
        textSize: "14px",
        markingColor: "none-black",
        textType: "Helvetica",
        textPresentation: "full",
        readSpeed: "1.0",
        currentBook: "0",
        currentTitle: "Ingen Titel",
        currentAuthor: "John Doe",
        textMode: 1,
        username: "",
        password: "",
        version: "dev5.8"
      };
      localStorage.setItem("mobileSettings", JSON.stringify(this.settings));
      return this.settings = JSON.parse(localStorage.getItem("mobileSettings"));
    };
    Application.prototype.SetSettings = function() {
      try {
        return localStorage.setItem("mobileSettings", JSON.stringify(this.settings));
      } catch (e) {
        return alert(e.message);
      }
    };
    Application.prototype.covercache = function(element) {
      return $(element).each(function() {
        var id, img, u;
        id = $(this).attr("id");
        u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg";
        return img = $(new Image()).load(function() {
          return $("#" + id).find("img").attr("src", u);
        }).error(function() {}).attr("src", u);
      });
    };
    Application.prototype.covercache_one = function(element) {
      var id, img, u;
      id = $(element).find("img").attr("id");
      u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg";
      return img = $(new Image()).load(function() {
        return $(element).find("img").attr("src", u);
      }).error(function() {}).attr("src", u);
    };
    Application.prototype.supports_local_storage = function() {
      try {
        if (window["localStorage"] != null) {
          return true;
        }
      } catch (e) {
        return false;
      }
    };
    Application.prototype.parse_media_name = function(mediastring) {
      if (mediastring.indexOf("AA") !== -1) {
        return "Lydbog";
      } else {
        return "Lydbog med tekst";
      }
    };
    Application.prototype.onBookDetailsSuccess = function(data, status) {
      var s;
      $("#book-details-image").html("<img id=\"" + data.d[0].imageid + "\" class=\"nota-full\" src=\"/images/default.png\" />");
      s = "";
      if (data.d[0].totalcnt > 1) {
        s = "<p>Serie: " + data.d[0].series + ", del " + data.d[0].seqno + " af " + data.d[0].totalcnt + "</p>";
      }
      $("#book-details-content").empty();
      $("#book-details-content").append("<h2>" + data.d[0].title + "</h2>" + "<h4>" + data.d[0].author + "</h4>" + "<a href=\"javascript:PlayNewBook(" + data.d[0].imageid + ", '" + data.d[0].title.replace("'", "") + "','" + data.d[0].author + "')\" data-role=\"button\" data-inline=\"true\">Afspil</a>" + "<p>" + parse_media_name(data.d[0].media) + "</p>" + "<p>" + data.d[0].teaser + "</p>" + s).trigger("create");
      return this.covercache_one($("#book-details-image"));
    };
    Application.prototype.onBookDetailsError = function(msg, data) {
      $("#book-details-image").html("<img src=\"/images/default.png\" />");
      return $("#book-details-content").html("<h2>Hov!</h2>" + "<p>Der skulle have været en bog her - men systemet kan ikke finde den. Det beklager vi meget! <a href=\"mailto:info@nota.nu?subject=Bog kunne ikke findes på E17 mobilafspiller\">Send os gerne en mail om fejlen</a>, så skal vi fluks se om det kan rettes.</p>");
    };
    Application.prototype.onSearchSuccess = function(data, status) {
      var s;
      s = "";
      if (data.d[0].resultstatus !== "NORESULTS") {
        s += "<li><h3>" + data.d[0].totalcount + " resultat(er)</h3></li>";
        return $.each(data.d, function(index, item) {
          return s += "<li id=\"" + item.imageid + "\"><a href=\"#book-details\">" + "<img class=\"ui-li-icon\" src=\"/images/default.png\" /><h3>" + item.title + "</h3><p>" + item.author + " | " + parse_media_name(item.media) + "</p></a></li>";
        });
      } else {
        s += "<li><h3>Ingen resultater</h3><p>Prøv eventuelt at bruge bredere søgeord. For at teste funktionen, søg på et vanligt navn, såsom \"kim\" eller \"anders\".</p></li>";
        return $("#searchresult").html(s);
      }
    };
    onSearchError = function(msg, data) {
      return $("#searchresult").text("Error thrown: " + msg.status);
    };
    Application.prototype.onSearchComplete = function() {
      $("#searchresult").listview("refresh");
      $("#searchresult").find("a:first").css("padding-left", "40px");
      $.mobile.hidePageLoadingMsg();
      return this.covercache($("#searchresult").html());
    };
    Application.prototype.PlayNewBook = function(id, title, author) {
      $.mobile.showPageLoadingMsg();
      Pause();
      this.settings.currentBook = id.toString();
      this.settings.currentTitle = title;
      this.settings.currentAuthor = author;
      this.SetSettings();
      $("#currentbook_image").find("img").attr("src", "/images/default.png").trigger("create");
      $("#currentbook_image").find("img").attr("id", this.settings.currentBook).trigger("create");
      $("#book_title").text(title);
      $("#book_author").text(author);
      $("#book_chapter").text(0);
      $("#book_time").text(0);
      $.mobile.showPageLoadingMsg();
      window.fileInterface.GetBook(this.settings.currentBook);
      return Play();
    };
    Application.prototype.eventSystemLoggedOn = function(loggedOn, id) {
      if (id !== -1) {
        this.settings.username = id;
        this.SetSettings();
      }
      if (loggedOn) {
        console.log("GUI: Event system logged on - kalder goto " + this.goto);
        return this.gotoPage();
      } else {
        $.mobile.hidePageLoadingMsg();
        return $.mobile.changePage("#login");
      }
    };
    Application.prototype.eventSystemLoggedOff = function(LoggedOff) {
      if (console) {
        console.log("GUI: Event system logged off");
      }
      $.mobile.hidePageLoadingMsg();
      this.goto = "bookshelf";
      if (LoggedOff) {
        return $.mobile.changePage("#login");
      }
    };
    Application.prototype.eventSystemNotLoggedIn = function(where) {
      this.goto = where;
      if (this.settings.username !== "" && this.settings.password !== "") {
        if (console) {
          console.log("GUI: Event system not logged in, logger på i baggrunden");
        }
        return window.fileInterface.LogOn(this.settings.username, this.settings.password);
      } else {
        return $.mobile.changePage("#login");
      }
    };
    Application.prototype.eventSystemForceLogin = function(response) {
      alert(response);
      $.mobile.hidePageLoadingMsg();
      return $.mobile.changePage("#login");
    };
    Application.prototype.eventSystemGotBook = function(bookTree) {
      $.mobile.hidePageLoadingMsg();
      $("#book-play #book-text-content").html(window.globals.text_window);
      GetTextAndSound(PLAYLIST[0]);
      $("#book_index_content").empty();
      $("#book_index_content").append(bookTree);
      return $.mobile.changePage("#book-play");
    };
    Application.prototype.eventSystemGotBookShelf = function(bookShelf) {
      var aBookShelf, addMore, nowPlaying;
      this.goto = "";
      this.full_bookshelf = bookShelf;
      console.log(this.full_bookshelf);
      $("#bookshelf-content").empty();
      aBookShelf = "";
      nowPlaying = "";
      addMore = "";
      $(bookShelf).find("contentItem:lt(" + this.bookshelf_showitems + ")").each(__bind(function() {
        var author, delimiter, title;
        delimiter = $(this).text().indexOf("$");
        author = $(this).text().substring(0, delimiter);
        title = $(this).text().substring(delimiter + 1);
        if ($(this).attr("id") === this.settings.currentBook) {
          return nowPlaying = "<li id=\"" + $(this).attr("id") + "\" title=\"" + title.replace("'", "") + "\" author=\"" + author + "\" ><a href=\"javascript:playCurrent();\"><img class=\"ui-li-icon\" src=\"/images/default.png\" />" + "<h3>" + title + "</h3><p>" + author + " | afspiller nu</p></a></li>";
        } else {
          return aBookShelf += "<li id=\"" + $(this).attr("id") + "\" title=\"" + title.replace("'", "") + "\" author=\"" + author + "\"><a href='javascript:PlayNewBook(" + $(this).attr("id") + ", \" " + title.replace("'", "") + " \" , \" " + author + " \")'><img class=\"ui-li-icon\" src=\"/images/default.png\" />" + "<h3>" + title + "</h3><p>" + author + "</p></a><a href=\"javascript:if(confirm('Fjern " + title.replace("'", "") + " fra din boghylde?')){ReturnContent(" + $(this).attr("id") + ");}\" >Fjern fra boghylde</a></li>";
        }
      }, this));
      if ($(this.full_bookshelf).find("contentList").attr("totalItems") > this.bookshelf_showitems) {
        addMore = "<li id=\"bookshelf-end \"><a href=\"javascript:addBooks()\">Hent flere bøger på min boghylde</p></li>";
      }
      $.mobile.changePage("#bookshelf");
      $("#bookshelf-content").append("<ul data-split-icon=\"delete\" data-split-theme=\"d\" data-role=\"listview\" id=\"bookshelf-list\">" + nowPlaying + aBookShelf + addMore + "</ul>").trigger("create");
      return this.covercache($("#bookshelf-list").html());
    };
    Application.prototype.addBooks = function() {
      this.bookshelf_showitems += 5;
      return this.eventSystemGotBookShelf(this.full_bookshelf);
    };
    Application.prototype.eventSystemPause = function(aType) {
      $("#button-play").find("img").attr("src", "/images/play.png").trigger("create");
      if (aType === Player.Type.user) {
        ;
      } else {
        return aType === Player.Type.system;
      }
    };
    Application.prototype.eventSystemPlay = function(aType) {
      $("#button-play").find("img").attr("src", "/images/pause.png").trigger("create");
      if (aType === Player.Type.user) {
        ;
      } else {
        return aType === Player.Type.system;
      }
    };
    Application.prototype.eventSystemTime = function(t) {
      var current_percentage, total_secs, tt;
      total_secs = void 0;
      current_percentage = void 0;
      if ($("#NccRootElement").attr("totaltime") != null) {
        tt = $("#NccRootElement").attr("totaltime");
        if (tt.length === 8) {
          total_secs = tt.substr(0, 2) * 3600 + (tt.substr(3, 2) * 60) + parseInt(tt.substr(6, 2));
        }
        if (tt.length === 7) {
          total_secs = tt.substr(0, 1) * 3600 + (tt.substr(2, 2) * 60) + parseInt(tt.substr(5, 2));
        }
        if (tt.length === 5) {
          total_secs = tt.substr(0, 2) * 3600 + (tt.substr(3, 2) * 60);
        }
      }
      current_percentage = Math.round(t / total_secs * 98);
      $("#current_time").text(SecToTime(t));
      $("#total_time").text($("#NccRootElement").attr("totaltime"));
      return $("#timeline_progress_left").css("width", current_percentage + "%");
    };
    Application.prototype.eventSystemTextChanged = function(textBefore, currentText, textAfter, chapter) {
      try {
        window.globals.text_window.innerHTML = "";
        if (chapter === "" || !(chapter != null)) {
          chapter = "Kapitel";
        }
        if (chapter.length > 14) {
          chapter = chapter.substring(0, 14) + "...";
        }
        $("#book_chapter").text(chapter);
        if (currentText.nodeType !== undefined) {
          window.globals.text_window.appendChild(document.importNode(currentText, true));
          $("#book-text-content").find("img").each(function() {
            var img, oldimage, rep_src;
            rep_src = $(this).attr("src").replace(/\\/g, "\\\\");
            oldimage = $(this);
            return img = $(new Image()).load(function() {
              var position;
              $(oldimage).replaceWith($(this));
              $(oldimage).attr("src", $(this).attr("src"));
              $(this).css("max-width", "100%");
              position = $(this).position();
              return $.mobile.silentScroll(position.top);
            }).error(function() {}).attr("src", rep_src);
          });
          return $("#book-text-content h1 a, #book-text-content h2 a").css("color", this.settings.markingColor.substring(this.settings.markingColor.indexOf("-", 0) + 1)).trigger("create");
        } else {
          ;
        }
      } catch (e) {
        return alert(e);
      }
    };
    Application.prototype.eventSystemStartLoading = function() {
      return $.mobile.showPageLoadingMsg();
    };
    Application.prototype.eventSystemEndLoading = function() {
      return $.mobile.hidePageLoadingMsg();
    };
    Application.prototype.showIndex = function() {
      return $.mobile.changePage("#book_index");
    };
    Application.prototype.playCurrent = function() {
      if (isPlayerAlive()) {
        return $.mobile.changePage("#book-play");
      } else {
        return this.PlayNewBook(this.settings.currentBook, this.settings.currentTitle, this.settings.currentAuthor);
      }
    };
    Application.prototype.setDestination = function(where) {
      return this.goto = where;
    };
    Application.prototype.gotoPage = function() {
      if (console) {
        console.log("GUI: gotoPage - " + this.goto);
      }
      switch (this.goto) {
        case "bookshelf":
          window.fileInterface.GetBookShelf();
          return this.goto = "";
        default:
          if ($(".ui-page-active").attr("id") === "login") {
            return window.fileInterface.GetBookShelf();
          }
      }
    };
    Application.prototype.logUserOff = function() {
      this.settings.username = "";
      this.settings.password = "";
      this.SetSettings();
      return window.fileInterface.LogOff();
    };
    return Application;
  })();
  window.Application = Application;
}).call(this);
