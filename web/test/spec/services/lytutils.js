'use strict';

describe('Service: LYTUtils', function () {

  // load the service's module
  beforeEach(module('lyt3App'));

  // instantiate service
  var LYTUtils;
  beforeEach(inject(function (_LYTUtils_) {
    LYTUtils = _LYTUtils_;
  }));

  it('should do something', function () {
    expect(!!LYTUtils).toBe(true);
  });

});
