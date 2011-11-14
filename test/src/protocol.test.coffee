module "protocol"

asyncTest "logOn", 2, ->
  done = createAsyncCounter 2
  
  LYT.rpc("logOn", "test", "test")
    .then (result) ->
      equal result, true, "logOn should succeed"
    .always done
  
  requestVariant "fail", ->
    LYT.rpc("logOn", "test", "test")
      .fail (code, msg) ->
        equal code, -1, "logOn should fail"
      .always done


asyncTest "getServiceAttributes", 1, ->
  done = createAsyncCounter 1
  
  LYT.rpc("getServiceAttributes")
    .then (result) ->
      deepEqual result, ["test op"], "Response should contain the optional 'test op' operation"
    .always done


asyncTest "setReadingSystemAttributes", 2, ->
  done = createAsyncCounter 2
  
  LYT.rpc("setReadingSystemAttributes")
    .then (result) ->
      equal result, true, "setReadingSystemAttributes should succeed"
    .always done
  
  requestVariant "fail", ->
    LYT.rpc("setReadingSystemAttributes")
      .fail (code) ->
        equal code, -1, "setReadingSystemAttributes should fail"
      .always done


asyncTest "issueContent", 2, ->
  done = createAsyncCounter 2
  
  LYT.rpc("issueContent", 1)
    .then (result) ->
      equal result, true, "issueContent should succeed"
    .always done
  
  requestVariant "fail", ->
    LYT.rpc("issueContent", 1)
      .fail (code) ->
        equal code, -1, "issueContent should fail"
      .always done


asyncTest "getContentList", 1, ->
  done = createAsyncCounter 1
  
  LYT.rpc("getContentList")
    .then (result) ->
      deepEqual result, [{id: "1", label: "Bog$Forfatter"}, {id: "2", label: "Bog 2$En anden forfatter"}], "getContentList should return 2 objs"
    .always done


asyncTest "getContentResources", ->
  done = createAsyncCounter 1
  
  LYT.rpc("getContentResources")
    .then (resources) ->
      for own key, value of resources
        equal value, "/DodpDistributor/Distribute.aspx?session=9999&book=0000&file=//path/to/content/#{key}", "Resource should match expected URL"
    .always done
  

