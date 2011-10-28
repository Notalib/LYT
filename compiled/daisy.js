(function() {
  ({
    this.daisy: {
      getBookshelf: function() {
        return rpc("getContentList", "issued", 0, -1);
      },
      getBook: function(id) {
        return rpc("issueContent", id);
      },
      getBookmarks: function(id) {}
    }
  });
}).call(this);
