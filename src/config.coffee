# Central system configuration
LYT.config =
  
  # The level of logging:  
  #     0 = No logging
  #     1 = Errors
  #     2 = Everything
  logging: 2
  
  # rpc system config
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
    
  protocol:
    readingSystemAttributes:
      manufacturer: "NOTA"
      model:        "LYT"
      serialNumber: "1"
      version:      "1"
      config:       null
  
  service:
    logOnAttempts: 3
    
  
