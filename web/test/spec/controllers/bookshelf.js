'use strict';

describe( 'Controller: BookshelfCtrl', function( ) {

  // load the controller's module
  beforeEach( module( 'lyt3App' ) );

  var BookshelfCtrl,
    scope;

  // Initialize the controller and a mock scope
  beforeEach( inject( function( $controller, $rootScope ) {
    scope = $rootScope.$new( );
    BookshelfCtrl = $controller( 'BookshelfCtrl', {
      $scope: scope
    } );
  } ) );

  xit( 'should attach a list of awesomeThings to the scope', function( ) {
    expect( scope.awesomeThings.length ).toBe( 3 );
  } );
} );
