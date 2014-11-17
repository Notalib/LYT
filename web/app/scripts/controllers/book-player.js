'use strict';

angular.module('lyt3App')
  .controller('BookPlayerCtrl', [ '$scope', '$log', 'NativeGlue', '$routeParams', 'Book',
    function( $scope, $log, NativeGlue, $routeParams, Book ) {
      Book.load( $routeParams.bookid ).then(function(book) {
        $scope.book = book;
      } );

      $scope.$on( 'play-time-update', function( bookId, offset ) {
        $log.info( 'play-time-update: TODO', bookId, offset );
      } );

      $scope.$on( 'end', function( bookId ) {
        $log.info( 'end: TODO', bookId );
      } );

      $scope.play = function() {
        NativeGlue.play( $routeParams.bookId );
      };

      $scope.stop = function() {
        NativeGlue.stop( );
      };
    } ] );
