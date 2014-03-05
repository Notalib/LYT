# Requires `/lyt`
# Requires `/support/globals/log`

# -------------------

# This file contains various configuration options for different parts of the app

# ## The level of logging:
#     0 = No logging
#     1 = Errors
#     2 = Errors & warnings
#     3 = Errors, warnings, and messages (default)
#

# ## Central system configuration
LYT.config =

  # ### LYT.rpc function config
  rpc:
    # The service's server-side URL
    url: "/DodpMobile/Service.svc" # No default - must be present

  # ### LYT.protocol config
  protocol:
    # The reading system attrs to send with
    # the `setReadingSystemAttributes` request
    # (No default - must be present)
    readingSystemAttributes:
      manufacturer: "NOTA"
      model:        "LYT"
      serialNumber: "1"
      version:      "1"
      config:       null

  # ### LYT.service config
  service:
    # The number of attempts to make when logging on
    # (multiple attempts are only made if the log on
    # process fails _unexpectedly_, i.e. connection
    # drops etc.) . If the server explicitly rejects
    # the username/password, `service` won't stupidly
    # try the same combo X more times.
    logOnAttempts: 3 # default: 3
    guestUser: "guest"
    guestLogin: "guest"

  # ### LYT.book module config

  book:
    states:
      pending:    'InProduction'
      available:  'Available'

  # ### LYT.bookshelf module config
  bookshelf:
    # Number of books to load per page
    pageSize: 5 # default: 5
    # Number of books to show on bookshelf (whitout show more)...
    maxShow: 20


  mobileMessage:
    GetVersion:
      url: "/mobileMessage/MobileMessage.svc/GetVersion"
    NotifyMe:
      url: "/mobileMessage/MobileMessage.svc/NotifyMe"
    LogError:
      url: "/mobileMessage/MobileMessage.svc/LogError"


  # ### LYT.google config
  google:
    # Autocomplete options
    autocomplete:
      # The URL to request results from
      url: "http://suggestqueries.google.com/complete/search?output=chrome&hl=dk&q="

  # ### LYT.catalog config
  catalog:
    # Full (free text) search options
    search:
      url: "/CatalogSearch/search.asmx/SearchCatalog" # No default - must be present
      pageSize: 10 # Default: 10

    # Autocomplete options
    autocomplete:
      # The URL to request results from
      url: "/CatalogSearch/search.asmx/Autocomplete" # No default - must be present
      # If suggestions from Autocomplete is léss than 'google_trigger' ask google
      google_trigger: 3

      # If we get answers from google, we only want as many as defined in google_answer_limit
      google_answer_limit:5

      # The options to pass to jQuery UI's `.autocomplete()`
      options:
        # Minimum length of text before autocompleting
        minLength: 2   # default: 1

        # Delay before autocompleting (milliseconds)
        delay:     300 # default: 300

    LookUpAutocompleteWords:
      url: "/CatalogSearch/search.asmx/LookUpAutocompleteWords"

    suggestions:
      url: "/CatalogSearch/search.asmx/GetPushItems"

    details:
      url: "/CatalogSearch/search.asmx/GetItemById"

  # ### LYT.player config
  player:
    # The minimum time between lastmark updates (milliseconds)
    lastmarkUpdateInterval: 10000 # Default: 10000 (i.e. 10 secs)
    playAttemptLimit: 10
    # Fakeend disabled because it triggers a race condition in
    # the section loading code.
    useFakeEnd: false

  segment:
    preload:
      queueSize: 3
    imagePreload:
      timeout: 1000000000
      attempts: 5

  # ### LYT.DTBDocument config
  dtbDocument:
    # Whether to use the `forceclose=true` parameter
    useForceClose: yes # Default: yes
    # Number of attempts to make when fetching a file
    attempts:      3   # Default: 3

  # ### LYT.NCCDocument config
  nccDocument:
    metaSections:
      # Format is "attribute value": "attribute type"
      #"title":             "class" # Don't skip the title and booknumber
      #"dbbcopyright":      "class" # Don't skip copyright disclaimer
      "dbbintro":           "class"
      "rearcover":          "class"
      "summary":            "class"
      "rightflap":          "class"
      "leftflap":           "class"
      "extract":            "class"
      "authorbiography":    "class"
      "kolofon":            "class"
      "andre oplysninger":  "class"
      "andre titler":       "class"
      "oplysninger":        "class"
      "forord":             "class"
      "indhold":            "class"
      "acknowledgements":   "class"
      "tak":                "class"
      "dedication":         "class"

      "GBIB":               "id"
      "GINFO":              "id"
      "GFLAP":              "id"

  # default page redirect page
  defaultPage:
    hash: '#bookshelf'

  settings:
    showAdvanced: no

