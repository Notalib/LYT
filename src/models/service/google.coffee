LYT.google = do ->
  jsonResults=[]
  deferred = null

  gotValues: (json)->
    if not json? or json.length < 2
      log.message 'Google: GotValues: error from google autocomplete'
      return deferred.reject()

    # JsonResults results from google....
    jsonResults = []
    # The searchterm is located in json[0] - We look in json[1] to see the results. 
    jQuery.each json[1], (i, val) ->
      # TODO: There is an ERROR in CatalogSearch -> AutoComplete will give result on "http://xxxx/xxxx.xxx" -> Search will not
      if val.indexOf('//') is -1
        # Put google results in array
        jsonResults.push(val)

    if jsonResults.length is 0
      return deferred.reject()
    if jsonResults.length > LYT.config.catalog.autocomplete.google_answer_limit
      jsonResults = jsonResults.slice 0, LYT.config.catalog.autocomplete.google_answer_limit

    LYT.catalog.lookUpAutocompleteWords(jsonResults)
      .done (data) ->
        deferred.resolve data
      .fail ->
        deferred.reject()

  doAutoComplete: (term)->
    deferred = jQuery.Deferred()

    jQuery.getScript(LYT.config.google.autocomplete.url + "#{term}&callback=LYT.google.gotValues")
      .fail ->
        deferred.reject()
        log.message 'Google: DoAutoComplete: error from google autocomplete link'
    # Return deffered to listen on....
    deferred.promise()
