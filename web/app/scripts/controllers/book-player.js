'use strict';

angular.module('lyt3App')
  .controller('BookPlayerCtrl', [ '$scope', '$log', '$location', 'LYTConfig',
    'NativeGlue', '$routeParams', 'BookService', 'BookNetwork',
    function( $scope, $log, $location, LYTConfig, NativeGlue, $routeParams, BookService, BookNetwork ) {
      if ( !$routeParams.bookid || isNaN( $routeParams.bookid ) ) {
        $location.path( '/' );
      }

      $scope.bookid = $routeParams.bookid;
      $scope.BookService = BookService;

      var loadBook = function( ) {
        $log.info( 'BookPlayerCtrl: play book' );
        BookService.loadBook( $routeParams.bookid );
      };

      var logonRejected = $scope.$on( 'logon:rejected', function( ) {
        $log.warn( 'TODO: Handle invalid login' );
        BookNetwork
          .logOn( LYTConfig.service.guestUser, LYTConfig.service.guestLogin )
            .then( function( ) {
              loadBook( );
            } );

        logonRejected( );
      } );


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

              $scope.startTime = ( currentSMIL.absoluteOffset ).toFixed(0);
              $scope.endTime   = ( currentSMIL.absoluteOffset + currentSMIL.duration ).toFixed(0);
              $scope.duration  = currentSMIL.duration;
            }

            $scope.currentTime = offset.toFixed(2);
            if ( offset.toFixed(0) === $scope.endTime ) {
              // Since currentTime is rounded to two decimals and endTime is rounded to one,
              // currentTime could be at the end of the segment but be shown as less than the entime.
              $scope.currentTime = $scope.endTime;
            }

            $scope.percentTime = ( $scope.currentTime - $scope.startTime ) / $scope.duration * 100;
            if ( navigationItem ) {
              $scope.sectionTitle = navigationItem.title;
            }
          } );
      } );

      $scope.toogle = function( ) {
        if ( BookService.playing ) {
          delete BookService.playing;

          BookService.stop();
        } else {
          BookService.play();
          BookService.playing = true;
        }
      };

      $scope.$on( 'end', function( bookId ) {
        $log.info( 'end: TODO', bookId );
      } );

      $log.info( 'BookPlayerCtrl: initialized' );
      loadBook( );
    } ] );
