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
