LYT.google = do ->
  jsonResults=[]
  deferred = null
  countNotaAutoComplete = 0


  jQuery(LYT.catalog).bind "autocomplete", (event) ->
    countNotaAutoComplete = event.results.length #length of results

  GotValues : (jason)->
    try
        #jsonResults results from google....
      jsonResults = []
      resultsMatch = []

      jQuery.each jason[1],(i, val) ->
        jsonResults.push(val) #put resultat i arrayet fra google
      
      if jsonResults.length is 0
        deferred.reject()
      if countNotaAutoComplete is 0 #only come with surgestions if autocomplete is blank...
        jQuery.each jsonResults,(i)->
          lookup = LYT.catalog.getAutoComplete(this)#look up google surgestions in nota autocomplete..
            .done (data) ->
              if data.length > 0
                resultsMatch.push(jsonResults[i])#if google surgestion is in nota.....
              if i is jsonResults.length-1
                if resultsMatch.length > 0
                  deferred.resolve resultsMatch
                else
                  deferred.reject()
            .fail ->
              deferred.reject() #something went wrong in notaautocomplete -> normal search
         
      else
        deferred.reject() #nota autocomplete is not blank -> normal search
    catch e
      log.message 'error from google autocomplete'+e
      deferred.reject()

  DoAutoComplete : (term)->
  	deferred = jQuery.Deferred()

  	jQuery.getScript(LYT.config.google.autocomplete.url + "#{term}&callback=LYT.google.GotValues")
  	  .fail ->
        deferred.reject()
        log.message 'error from google autocomplete link'

  	deferred.promise() #return deffered to listen on....

  #http://suggestqueries.google.com/complete/search?hl=en&ds=yt&json=t&jsonp=callbackfunction&q=orange+county+ca
  #http://suggestqueries.google.com/complete/search?output=chrome&hl=dk&q=
  #http://suggestqueries.google.com/complete/search?output=firefox&client=firefox&hl=dk&json=t&jsonp=callbackfunction&q=harp
  #http://suggestqueries.google.com/complete/search?ds=yt&output=toolbar&hl=dk&q=harry
  #http://suggestqueries.google.com/complete/search?output=chrome&hl=dk&q=harry&callback=arne