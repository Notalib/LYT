# The level of logging:  
#     0 = No logging
#     1 = Errors
#     2 = Errors & warnings
#     3 = Errors, warnings, and messages (everything)
# FIXME: Quick hack to lessen the logging on mobile devices
log.level = if /android.+mobile|blackberry|iemobile|ip(hone|ad|od)/i.test (navigator.userAgent or navigator.vendor) then 2 else 3

# Central system configuration
LYT.config =
  
  # LYT.rpc function config
  rpc:
    # The default set of options to pass to jQuery's ajax functions
    options:
      async:       yes
      cache:       no
      contentType: "text/xml; charset=utf-8"
      data:        null
      dataType:    "xml"
      headers:     null
      processData: yes
      timeout:     10000
      type:        "POST"
      url:         "/DodpMobile/Service.svc"
  
  # Values used by protocol functions
  protocol:
    # The reading system attrs to send with
    # the `setReadingSystemAttributes` request
    readingSystemAttributes:
      manufacturer: "NOTA"
      model:        "LYT"
      serialNumber: "1"
      version:      "1"
      config:       null
  
  # LYT.service config
  service:
    logOnAttempts: 3
  
  # LYT.bookshelf module config
  bookshelf:
    pageSize: 5
  
  # LYT.search config
  search:
    # Full (free text) search options
    full:
      url: "/CatalogSearch/search.asmx/SearchFlex"
      pageSize: 10
    
    # Autocomplete options
    autocomplete:
      # The URL to request results from
      url: "/CatalogSearch/search.asmx/SearchAutocomplete"
      # The options to pass to jQuery UI's `.autocomplete()`
      setup:
        minLength: 2
  
  dtbDocument:
    useForceClose: yes
