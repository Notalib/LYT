(function() {
  this.config = {
    logging: 2,
    rpc: {
      options: {
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
    }
  };
}).call(this);
