# Requires `config`

# -------------------

# Configuration settings that apply to an MTM environment
jQuery.extend true, LYT.config,
  isE17: false
  isMTM: true

  rpc:
    url: "http://dodexttest.mtm.se/dodServices/"
    proxyToLocal: false

  catalog:
    autocomplete:
      enabled: false
