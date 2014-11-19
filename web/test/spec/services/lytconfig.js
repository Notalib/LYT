'use strict';

describe('Service: LYTConfig', function () {

  // load the service's module
  beforeEach(module('lyt3App'));

  // instantiate service
  var LYTConfig;
  beforeEach(inject(function (_LYTConfig_) {
    LYTConfig = _LYTConfig_;
  }));

  it('should do something', function () {
    expect(!!LYTConfig).toBe(true);
  });

});
