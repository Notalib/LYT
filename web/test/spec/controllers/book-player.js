'use strict';

describe('Controller: BookPlayerCtrl', function() {

  // load the controller's module
  beforeEach(module('lyt3App'));

  var BookPlayerCtrl,
    scope;

  // Initialize the controller and a mock scope
  beforeEach(inject( function( $controller, $rootScope ) {
    scope = $rootScope.$new();
    BookPlayerCtrl = $controller('BookPlayerCtrl', {
      $scope: scope
    });
  }));
});
