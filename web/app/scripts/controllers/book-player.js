'use strict';

angular.module('lyt3App')
  .controller('BookPlayerCtrl', [ '$scope', '$log', 'NativeGlue', '$routeParams',
    'BookService', '$interval', '$location',
    function( $scope, $log, NativeGlue, $routeParams, BookService, $interval, $location ) {
      if ( !$routeParams.bookid || isNaN( $routeParams.bookid ) ) {
        $location.path( '/' );
      }

      $scope.BookService = BookService;

      BookService.loadBook( $routeParams.bookid );

      var currentSMIL;
      $scope.$watch( 'BookService.currentBook.currentPosition', function( offset ) {
        if ( !BookService.currentBook ) {
          return;
        }

        BookService.currentBook.findSegmentFromOffset( offset )
          .then( function( segment ) {
            var smil = segment.document;
            var navigationItem = BookService.currentBook.structure.navigation
              .reduce( function( output, current ) {
                if ( current.offset <= offset ) {
                  output = current;
                }
                return output;
              }, {} );

            if ( currentSMIL !== smil ) {
              currentSMIL = smil;

              $scope.startTime = Math.floor( currentSMIL.absoluteOffset );
              $scope.endTime   = Math.ceil( currentSMIL.absoluteOffset + currentSMIL.duration );
              $scope.duration  = currentSMIL.duration;
            }

            $scope.currentTime = Math.round( offset * 100 ) / 100;
            $scope.percentTime = ( $scope.currentTime - $scope.startTime ) / $scope.duration * 100;
            if ( navigationItem ) {
              $scope.sectionTitle = navigationItem.title;
            }
          } );
      } );

      $scope.toogle = function( ) {
        if ( BookService.playing ) {
          $interval.cancel( BookService.playing );
          delete BookService.playing;

          BookService.stop();
        } else {
          try {
            BookService.play();
            BookService.playing = true;
          } catch ( e ) {
            if ( BookService.playing ) {
              $interval.cancel( BookService.playing );
            }

            // Fake progress
            var lastTime = new Date() / 1000;
            BookService.playing = $interval( function( ) {
              var now = new Date( ) / 1000;
              $scope.$emit( 'play-time-update', BookService.currentBook.id, BookService.currentBook.currentPosition + now - lastTime );
              lastTime = now;
            }, 250 );
          }
        }
      };

      $scope.$on( 'end', function( bookId ) {
        $log.info( 'end: TODO', bookId );
      } );
    } ] );
