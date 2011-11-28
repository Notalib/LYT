module "service"

asyncTest "logOn", 3, ->
  mark = createAsyncCounter 3
  
  jQuery(LYT.service).bind "logon:rejected", ->
    ok true, "service should emit logon:rejected error"
    mark()
  
  LYT.service.logOn("test", "test")
    .done ->
      ok true, "logon should succeed"
    .always ->
      mark()
      requestVariant "fail", ->
        LYT.service.logOn("test", "test")
          .fail ->
            ok true, "logon should fail"
          .always mark


asyncTest "getBookshelf", 1, ->
  mark = createAsyncCounter 1

  LYT.service.logOn("test", "test").done ->
    requestVariant "fail", ->
      LYT.service.getBookshelf()
      .done ->
        ok true, "getBookshelf should succeed"
      .always mark

