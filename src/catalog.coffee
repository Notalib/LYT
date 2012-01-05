# This module handles searching and search-suggestions

# --------

# ## Constants

window.SEARCH_GENERAL_ERROR = {}

# --------

# Define the `LYT.catalog` object
LYT.catalog = do ->
  
  autocompleteCache = {}
  
  # Sorting options for the server-side function
  SORTING_OPTIONS =
    "new":        1 # default
    "lastmonth":  2
    "last3month": 3
    "thisyear":   4
    "forever":    5
    "author":     6
    "title":      7
    "yearasc":    8
    "yeardesc":   9
    "series":     10
  
  # Fields to be searched by the server-side function
  FIELD_OPTIONS =
    "freetext": 0 # all fields (default)
    "author":   1
    "title":    2
    "keywords": 3
    "speaker":  4
    "teaser":   5
    "series":   6
  
  # Internal helper to build the AJAX options.  
  # Takes to 2 arguments: The URL to call, and
  # and the data (as an object) to send
  getAjaxOptions = (url, data) ->
    dataType:    "json"
    type:        "POST"
    contentType: "application/json; charset=utf-8"
    data:        JSON.stringify data
    url:         url
  
  
  # Perform a "full" search. Takes the search term as its
  # only argument, and returns a deferred object.  
  # The deferred object will resolve with an array of search
  # result objects (or an empty array, if there are no results).  
  # In case of an error, the deferred will be rejected with the
  # `SEARCH_GENERAL_ERROR` constant, the response status, and
  # the error thrown
  search = (term, page = 1) ->
    # Get the search params
    params =
      term: term
      options:
        pagesize: LYT.config.catalog.search.pageSize or 10
        pagenbr:  page
    
    # Get the ajax options
    options = getAjaxOptions LYT.config.catalog.search.url, params
    
    # Create the deferred
    deferred = jQuery.Deferred()
    
    # Add the `success` and `error` handlers
    options.success = createResponseHandler deferred, page
    options.error   = createErrorHandler deferred
    
    # Perform the request
    jQuery.ajax options
    
    # Return the deferred
    deferred
  
  
  # Create an AJAX success handler (this could be inside `search`,
  # but has been placed here for clarity)
  createResponseHandler = (deferred, currentPage) ->
    (data, status, jqHXR) ->
      results = []
      if data.d? and data.d.length > 0 and not (/noresults/i).test data.d[0].results
        results = (for item in data.d
          {
            id:     item.itemid
            title:  item.title
            author: item.author
            media:  item.media
          }
        )
      
      # TODO: Temporary "solution", until the server response gets
      # updated with a "number of pages" or "next page available"
      # value
      results.currentPage = currentPage
      if results.length >= (LYT.config.catalog.search.pageSize or 10)
        results.nextPage = currentPage + 1
      else
        results.nextPage = false
      
      deferred.resolve results
  
  
  # Create an AJAX error handler (this could be inside `search`,
  # but has been placed here for clarity)
  createErrorHandler = (deferred) ->
    (jqXHR, status, error) ->
      if status is 404
        # HTTP 404 could mean "no results", so handle that here
        deferred.resolve []
      else
        # An error ocurred
        deferred.reject SEARCH_GENERAL_ERROR, status, error
  
  
  # ---------------
  
  # ## Autocomplete functions
  # See jQuery UI's [`.autocomplete()`](http://docs.jquery.com/UI/Autocomplete)  
  #
  # To listen for autocomplete suggestions, add an event listener:
  #
  #     jQuery(LYT.catalog).bind "autocomplete", (event) ->
  #       # results are passed as event.data
  # 
  
  
  # Attach the autocomplete eventhandler to the element passed
  attachAutocomplete = (element) ->
    jQuery(element).autocomplete getAutocompleteOptions()
  
  
  # Returns an options array for the autocomplete function.
  getAutocompleteOptions = ->
    # Clone the autocomplete options from config
    setup = jQuery.extend {}, (LYT.config.catalog.autocomplete.setup or {})
    
    # Add the `source` callback
    setup.source = (request, response) ->
      # Create the AJAX options. Since `request` is a simple object containing
      # a single value, called `term`, the request object can be sent directly
      # to the `getAjaxOptions` helper
      options = getAjaxOptions LYT.config.catalog.autocomplete.url, request
      
      # An internal function to be called when the AJAX call completes
      complete = (results) ->
        # Send the results - empty or not - back to the jQuery
        # UI's autocomplete function (the `response` callback
        # must always be called, regardless of whether the AJAX
        # call succeeded or not)
        response results
        
        # Emit an event with the results attached as `event.results` 
        event = jQuery.Event "autocomplete"
        event.results = results
        #log.message "Search: Emitting autocomplete event"
        jQuery(LYT.catalog).trigger event
      
      if autocompleteCache[request.term]?
        complete autocompleteCache[request.term]
        return
      
      # Perform the request
      jQuery.ajax(options)
        # On success, extract the results
        .done (data) ->
          results = data.d or []
          autocompleteCache[request.term] = results
          complete results
        # On fail, just call `complete`
        .fail complete
    
    # Return the setup object
    setup
  
  
  # Expose the functions
  search:                 search
  attachAutocomplete:     attachAutocomplete
  getAutocompleteOptions: getAutocompleteOptions

