'use strict';

angular.module('lyt3App')
  .controller('BookPlayerCtrl', [ '$scope', '$log', 'NativeGlue', '$routeParams', 'Book',
    function( $scope, $log, NativeGlue, $routeParams, Book ) {
      Book.load( $routeParams.bookid ).then( function( book ) {
        $scope.book = book;
        book.getStructure( ).then( function( bookData ) {
          NativeGlue.setBook( bookData );
        } );
      } );

      $scope.$on( 'play-time-update', function( bookId, offset ) {
        $log.info( 'play-time-update: TODO', bookId, offset );

        $scope.book.findSectionFromOffset( offset )
          .then( function( segment ) {
            console.log( segment );
          } );
      } );

      $scope.$on( 'end', function( bookId ) {
        $log.info( 'end: TODO', bookId );
      } );

      $scope.play = function() {
        NativeGlue.play( $routeParams.bookid );
      };

      $scope.stop = function() {
        NativeGlue.stop( );
      };
    } ] );
