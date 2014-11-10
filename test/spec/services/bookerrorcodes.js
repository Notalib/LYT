'use strict';

describe('Service: BookErrorCodes', function () {

  // load the service's module
  beforeEach(module('lyt3App'));

  // instantiate service
  var BookErrorCodes;
  beforeEach(inject(function (_BookErrorCodes_) {
    BookErrorCodes = _BookErrorCodes_;
  }));

  it('should do something', function () {
    expect(!!BookErrorCodes).toBe(true);
  });

});
