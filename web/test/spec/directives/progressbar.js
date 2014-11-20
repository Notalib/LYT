'use strict';

describe('Directive: progressbar', function() {

  // load the directive's module
  beforeEach(module('lyt3App'));

  var element,
    scope;

  beforeEach( inject( function($rootScope) {
    scope = $rootScope.$new();
  } ) );

  it('should make hidden element visible', inject( function($compile) {
    element = angular.element('<progressbar></progressbar>');
    element = $compile(element)(scope);
    expect(element.text()).toBe('this is the progressbar directive');
  }));
});
