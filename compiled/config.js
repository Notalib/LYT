(function() {
  LYT.config = {
    logging: 2,
    rpc: {
      options: {
        async: true,
        cache: false,
        contentType: "text/xml; charset=utf-8",
        data: null,
        dataType: "xml",
        headers: null,
        processData: true,
        timeout: 30000,
        type: "POST",
        url: "/DodpMobile/Service.svc"
      }
    },
    protocol: {
      readingSystemAttributes: {
        manufacturer: "NOTA",
        model: "LYT",
        serialNumber: "1",
        version: "1",
        config: null
      }
    }
  };
}).call(this);
