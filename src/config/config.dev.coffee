# Requires `config`
# Requires `/support/globals/log`

# -------------------

# Configuration settings that apply when in development mode

# See support/globals/log.coffee for more information
jQuery.extend log,
  level: 3
  receiver: 'local'

jQuery.extend LYT.config,
  originDomain: null

  settings:
    showAdvanced: yes

  # ### LYT.rpc function config
  rpc:
    # The service's server-side URL
    url: "/DodpMobile/Service.svc" # No default - must be present

  mobileMessage:
    GetVersion:
      url: "/mobileMessage/MobileMessage.svc/GetVersion"
    NotifyMe:
      url: "/mobileMessage/MobileMessage.svc/NotifyMe"
    LogError:
      url: "/mobileMessage/MobileMessage.svc/LogError"

  navigation:
    # Single quotes are important here - otherwise this gets interpreted
    # as a template already by CoffeeScript
    backButtonURL: 'https://nota.dk//bibliotek/bogid/#{id}'

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
      url: 'https://nota.dk/bibliotek/notalogin'
      parameters:
        # Single quotes are important here - otherwise this gets interpreted
        # as a template already by CoffeeScript
        destination: 'redirectplay?url=#{url64}'
