QUnit.config.testTimeout = 5000
_originalURL = LYT.config.rpc.options.url

createAsyncCounter = (count = 1) ->
  -> --count or start()

setURL = (url) ->
  LYT.config.rpc.options.type = "GET"
  LYT.config.rpc.options.url  = url

module "protocol", {
  teardown: -> setURL _originalURL
}

asyncTest "logOn", 2, ->
  done = createAsyncCounter 2
  
  setURL "fixtures/protocol/logOn-ok.xml"
  LYT.rpc("logOn", "test", "test")
    .then (result) ->
      equal result, true
    .always done
  
  setURL "fixtures/protocol/logOn-fail.xml"
  LYT.rpc("logOn", "test", "test")
    .fail (code, msg) ->
      equal code, -1
    .always done


asyncTest "getServiceAttributes", 1, ->
  done = createAsyncCounter 1
  
  setURL "fixtures/protocol/getAttrs.xml"
  LYT.rpc("getServiceAttributes")
    .then (result) ->
      deepEqual result, ["test op"]
    .always done


asyncTest "setReadingSystemAttributes", 2, ->
  done = createAsyncCounter 2

  setURL "fixtures/protocol/setReadAttrs-ok.xml"
  LYT.rpc("setReadingSystemAttributes")
    .then (result) ->
      equal result, true
    .always done
  
  setURL "fixtures/protocol/setReadAttrs-fail.xml"
  LYT.rpc("setReadingSystemAttributes")
    .fail (code) ->
      equal code, -1
    .always done


asyncTest "issueContent", 2, ->
  done = createAsyncCounter 2

  setURL "fixtures/protocol/issueContent-ok.xml"
  LYT.rpc("issueContent", 1)
    .then (result) ->
      equal result, true
    .always done

  setURL "fixtures/protocol/issueContent-fail.xml"
  LYT.rpc("issueContent", 1)
    .fail (code) ->
      equal code, -1
    .always done


asyncTest "getContentList", 1, ->
  done = createAsyncCounter 1

  setURL "fixtures/protocol/getContentList.xml"
  LYT.rpc("getContentList")
    .then (result) ->
      deepEqual result, [{id: "1", label: "test 1"}, {id: "2", label: "test 2"}]
    .always done


asyncTest "getContentResources", 3, ->
  done = createAsyncCounter 1

  setURL "fixtures/protocol/getContentRes.xml"
  LYT.rpc("getContentResources")
    .then (resources) ->
      equal resources.smil.length, 2
      equal resources.mp3.length, 2
      equal resources.ncc, "http://test.test/123/ncc.html"
    .always done