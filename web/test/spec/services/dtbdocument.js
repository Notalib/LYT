'use strict';

describe('Service: DtbDocument', function () {

  // load the service's module
  beforeEach(module('lyt3App'));

  // instantiate service
  var DtbDocument;
  beforeEach(inject(function (_DtbDocument_) {
    DtbDocument = _DtbDocument_;
  }));

  it('should do something', function () {
    expect(!!DtbDocument).toBe(true);
  });

});
