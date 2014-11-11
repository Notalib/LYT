'use strict';

describe('Service: SMILDocument', function () {

  // load the service's module
  beforeEach(module('lyt3App'));

  // instantiate service
  var SMILDocument;
  beforeEach(inject(function (_SMILDocument_) {
    SMILDocument = _SMILDocument_;
  }));

  it('should do something', function () {
    expect(!!SMILDocument).toBe(true);
  });

});
