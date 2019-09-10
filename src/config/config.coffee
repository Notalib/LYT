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
  # If set, this changes document.domain to the given value. Useful when
  # serving the player from a subdomain like m.nota.dk
  originDomain: "nota.dk"

  # ### LYT.rpc function config
  rpc:
    # The service's server-side URL
    url: "//m.nota.dk/DodpMobile/Service.svc" # No default - must be present

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

  navigation:
    # Single quotes are important here - otherwise this gets interpreted
    # as a template already by CoffeeScript
    backButtonURL: '//nota.dk/bibliotek/bogid/#{id}'

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

    externalLogin:
      redirectOnNoBook: true
      url: '//nota.dk/bibliotek/notalogin'
      parameters:
        # Single quotes are important here - otherwise this gets interpreted
        # as a template already by CoffeeScript
        destination: 'redirectplay?url=#{url64}'

  # ### LYT.book module config

  book:
    states:
      pending:    'InProduction'
      available:  'Available'

  mobileMessage:
    GetVersion:
      url: "//m.nota.dk/mobileMessage/MobileMessage.svc/GetVersion"
    NotifyMe:
      url: "//m.nota.dk/mobileMessage/MobileMessage.svc/NotifyMe"
    LogError:
      url: "//m.nota.dk/mobileMessage/MobileMessage.svc/LogError"

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
    hash: '#book-player'

  settings:
    showAdvanced: no

  ## Setup LYT3 testers. Member ids from getNotaAuthToken() must be added to the testers array.
  LYT3:
    testers: ["10140346", "10140345", "10109178"]
    URL: "https://lbs-next.nota.dk/embedded/{bookid}"

