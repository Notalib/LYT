'use strict';

describe('Service: LYTSession', function () {

  // load the service's module
  beforeEach(module('lyt3App'));

  // instantiate service
  var LYTSession;
  beforeEach(inject(function (_LYTSession_) {
    LYTSession = _LYTSession_;
  }));

  it('should do something', function () {
    expect(!!LYTSession).toBe(true);
  });

});
