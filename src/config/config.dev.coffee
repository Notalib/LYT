# Requires `config`
# Requires `/support/globals/log`

# -------------------

# Configuration settings that apply when in development mode

# See support/globals/log.coffee for more information
jQuery.extend log,
  level: 3
  receiver: 'local'
  allowDevConsoleEvent: true

jQuery.extend true, LYT.config,
  rpc:
    proxyToLocal: true

  settings:
    showAdvanced: yes
