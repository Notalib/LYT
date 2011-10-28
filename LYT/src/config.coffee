# Central system configuration
@config =
  
  # The level of logging:  
  #     0 = No logging
  #     1 = Errors
  #     2 = Everything
  logging: 2
  
  # rpc system config
  rpc:
    # The default set of options to pass to jQuery's ajax functions
    options:
      cache:       no
      contentType: "text/xml; charset=utf-8"
      data:        null
      dataType:    "xml"
      headers:     null
      processData: true
      timeout:     30000
      type:        "POST"
      url:         "/DodpMobile/Service.svc"