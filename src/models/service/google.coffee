LYT.google = do ->
  jsonResults=[]
  deferred = null


  GotValues: (jason)->
    try
        #jsonResults results from google....
      jsonResults = []
      resultsMatch = []

      jQuery.each jason[1], (i, val) ->
        #TODO: There is a ERROR in CatalogSearch -> AutoComplete will give result on "http://xxxx/xxxx.xxx" -> Search will not 
        if val.indexOf('//') is -1
          jsonResults.push(val) #put resultat i arrayet fra google
      
      if jsonResults.length is 0
        deferred.reject()
      
      jQuery.each jsonResults, (i)->
        lookup = LYT.catalog.getAutoComplete(this)#look up google surgestions in nota autocomplete..
          .done (data) ->
            if data.length > 0
              resultsMatch.push(jsonResults[i])#if google surgestion is hits something in nota autocomplete (aka. Catalogsearch).
            if i is jsonResults.length-1
              if resultsMatch.length > 0
                deferred.resolve resultsMatch
              else
                deferred.reject()
          .fail ->
            deferred.reject() #something went wrong in notaautocomplete -> normal search
    catch e
      log.message 'Google: GotValues: error from google autocomplete'+e
      deferred.reject()

  DoAutoComplete: (term)->
    deferred = jQuery.Deferred()

    jQuery.getScript(LYT.config.google.autocomplete.url + "#{term}&callback=LYT.google.GotValues")
      .fail ->
        deferred.reject()
        log.message 'Google: DoAutoComplete: error from google autocomplete link'

    deferred.promise() #return deffered to listen on....

  #http://suggestqueries.google.com/complete/search?hl=en&ds=yt&json=t&jsonp=callbackfunction&q=orange+county+ca
  #http://suggestqueries.google.com/complete/search?output=chrome&hl=dk&q=
  #http://suggestqueries.google.com/complete/search?output=firefox&client=firefox&hl=dk&json=t&jsonp=callbackfunction&q=harp
  #http://suggestqueries.google.com/complete/search?ds=yt&output=toolbar&hl=dk&q=harry
  #http://suggestqueries.google.com/complete/search?output=chrome&hl=dk&q=harry&callback=arne