# Requires `config`

# -------------------

# Configuration settings that apply to an MTM environment
jQuery.extend true, LYT.config,
  isE17: false
  isMTM: true

  rpc:
    url: "/dodServices/"
    proxyResources: true

  catalog:
    autocomplete:
      enabled: false
