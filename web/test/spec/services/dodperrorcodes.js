'use strict';

describe('Service: DODPErrorCodes', function () {

  // load the service's module
  beforeEach(module('lyt3App'));

  // instantiate service
  var DODPErrorCodes;
  beforeEach(inject(function (_DODPErrorCodes_) {
    DODPErrorCodes = _DODPErrorCodes_;
  }));

  it('should do something', function () {
    expect(!!DODPErrorCodes).toBe(true);
  });

});
