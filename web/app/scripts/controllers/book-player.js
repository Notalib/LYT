'use strict';

angular.module('lyt3App')
  .controller('BookPlayerCtrl', [ '$scope', '$log', 'NativeGlue', '$routeParams', 'Book', '$interval',
    function( $scope, $log, NativeGlue, $routeParams, Book, $interval ) {
      var currentBookStructure;
      Book.load( $routeParams.bookid )
        .then( function( book ) {
          $scope.book = book;
          book.getStructure( ).then( function( bookData ) {
            currentBookStructure = bookData;

            // Fake progress
            var start = new Date() / 1000;
            $interval( function( ) {
              var now = new Date( ) / 1000;
              $scope.$emit( 'play-time-update', now - start );
            }, 250 );

            NativeGlue.setBook( bookData );
          } );
        } );

      var currentSMIL;
      $scope.$on( 'play-time-update', function( bookId, offset ) {
        // $log.info( 'play-time-update: TODO', bookId, offset );

        $scope.book.findSectionFromOffset( offset )
          .then( function( segment ) {
            var smil = segment.document;
            var navigationItem = currentBookStructure.navigation.reduce( function( output, current ) {
              if ( current.offset <= offset ) {
                output = current;
              }
              return output;
            }, {} );

            if ( currentSMIL != smil ) {
              currentSMIL = smil;

              $scope.startTime = Math.floor( currentSMIL.absoluteOffset );
              $scope.endTime = Math.ceil( currentSMIL.absoluteOffset + currentSMIL.duration );
              $scope.duration = currentSMIL.duration;
            }

            $scope.currentTime = Math.round( offset * 100 ) / 100;
            $scope.percentTime = ( $scope.currentTime - $scope.startTime ) / $scope.duration * 100;
            if ( navigationItem ) {
              $scope.sectionTitle = navigationItem.title;
            }
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
