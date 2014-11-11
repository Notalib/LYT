'use strict';

describe('Service: DtbBookmark', function () {

  // load the service's module
  beforeEach(module('lyt3App'));

  // instantiate service
  var DtbBookmark;
  beforeEach(inject(function (_DtbBookmark_) {
    DtbBookmark = _DtbBookmark_;
  }));

  it('should do something', function () {
    expect(!!DtbBookmark).toBe(true);
  });

});
