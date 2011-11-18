(function() {
  LYT.settings = {
    data: {
      textSize: "14px",
      markingColor: "none-black",
      textType: "Helvetica",
      textPresentation: "full",
      readSpeed: "1.0",
      textMode: 1
    },
    get: function(key) {
      return this.data[key];
    },
    set: function(key, value) {
      this.data[key] = value;
      return this.save();
    },
    load: function() {
      var data;
      data = LYT.cache.read("lyt", "settings");
      if (data !== null) {
        return this.data = data;
      }
    },
    save: function() {
      return LYT.cache.write("lyt", "settings", this.data);
    }
  };
}).call(this);
