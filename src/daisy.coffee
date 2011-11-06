# Higher-level functions for interacting with the server 

LYT.daisy:
  getBookshelf: ->
    LYT.rpc "getContentList", "issued", 0, -1
  
  getBook: (id) ->
    LYT.rpc "issueContent", id
  
  # Not implemented
  # FIXME: I don't get this part… the original `GetBookmarks` calls `GetBookmarksSync` which returns an XML _request_ string, which is the same that `SetBookmarks` sends… and `GetBookmarks` is never actually called… I'm confused!
  getBookmarks: (id) ->

