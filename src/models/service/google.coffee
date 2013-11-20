LYT.google = do ->
  jsonResults=[]
  deferred = null

  gotValues: (json)->
    try
      # JsonResults results from google....
      jsonResults = []
      resultsMatch = []

      jQuery.each json[1], (i, val) ->
        # TODO: There is an ERROR in CatalogSearch -> AutoComplete will give result on "http://xxxx/xxxx.xxx" -> Search will not
        if val.indexOf('//') is -1
          # Put google results in array
          jsonResults.push(val)

      if jsonResults.length is 0
        deferred.resolve resultsMatch

      LYT.catalog.LookUpAutocompleteWords(jsonResults)
        .done (data) ->
          deferred.resolve data
        .fail ->
          deferred.reject()
    catch e
      log.message 'Google: GotValues: error from google autocomplete'+e
      deferred.reject()

  doAutoComplete: (term)->
    deferred = jQuery.Deferred()

    jQuery.getScript(LYT.config.google.autocomplete.url + "#{term}&callback=LYT.google.gotValues")
      .fail ->
        deferred.reject()
        log.message 'Google: DoAutoComplete: error from google autocomplete link'
    # Return deffered to listen on....
    deferred.promise()

  #http://suggestqueries.google.com/complete/search?hl=en&ds=yt&json=t&jsonp=callbackfunction&q=orange+county+ca
  #http://suggestqueries.google.com/complete/search?output=chrome&hl=dk&q=
  #http://suggestqueries.google.com/complete/search?output=firefox&client=firefox&hl=dk&json=t&jsonp=callbackfunction&q=harp
  #http://suggestqueries.google.com/complete/search?ds=yt&output=toolbar&hl=dk&q=harry
  #http://suggestqueries.google.com/complete/search?output=chrome&hl=dk&q=harry&callback=arne
