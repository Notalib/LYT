(function() {
  LYT.gui = {
    covercache: function(element) {
      return $(element).each(function() {
        var id, img, u;
        id = $(this).attr("id");
        u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg";
        return img = $(new Image()).load(function() {
          return $("#" + id).find("img").attr("src", u);
        }).error(function() {}).attr("src", u);
      });
    },
    covercache_one: function(element) {
      var id, img, u;
      id = $(element).find("img").attr("id");
      u = "http://www.e17.dk/sites/default/files/bookcovercache/" + id + "_h80.jpg";
      return img = $(new Image()).load(function() {
        return $(element).find("img").attr("src", u);
      }).error(function() {}).attr("src", u);
    },
    parse_media_name: function(mediastring) {
      if (mediastring.indexOf("AA") !== -1) {
        return "Lydbog";
      } else {
        return "Lydbog med tekst";
      }
    },
    onBookDetailsSuccess: function(data, status) {
      var s;
      $("#book-details-image").html("<img id=\"" + data.d[0].imageid + "\" class=\"nota-full\" src=\"/images/default.png\" >");
      if (data.d[0].totalcnt > 1) {
        s = "<p>Serie: " + data.d[0].series + ", del " + data.d[0].seqno + " af " + data.d[0].totalcnt + "</p>";
      }
      $("#book-details-content").empty();
      $("#book-details-content").append("<h2>" + data.d[0].title + "</h2>" + "<h4>" + data.d[0].author + "</h4>" + "<a href=\"javascript:PlayNewBook(" + data.d[0].imageid + ", '" + data.d[0].title.replace("'", "") + "','" + data.d[0].author + "')\" data-role=\"button\" data-inline=\"true\">Afspil</a>" + "<p>" + parse_media_name(data.d[0].media) + "</p>" + "<p>" + data.d[0].teaser + "</p>" + s).trigger("create");
      return this.covercache_one($("#book-details-image"));
    },
    onBookDetailsError: function(msg, data) {
      $("#book-details-image").html("<img src=\"/images/default.png\" >");
      return $("#book-details-content").html("<h2>Hov!</h2>" + "<p>Der skulle have været en bog her - men systemet kan ikke finde den. Det beklager vi meget! <a href=\"mailto:info@nota.nu?subject=Bog kunne ikke findes på E17 mobilafspiller\">Send os gerne en mail om fejlen</a>, så skal vi fluks se om det kan rettes.</p>");
    }
  };
}).call(this);
