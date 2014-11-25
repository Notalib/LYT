'use strict';

angular.module('lyt3App')
  .filter('sec2time', [ 'LYTUtils', function( LYTUtils ) {
    return function( seconds, includeSecondsDecimal ) {
      seconds = Math.max( 0, seconds || 0 );
      var timeStr = LYTUtils.formatTime(seconds);

      if ( includeSecondsDecimal ) {
        var decimal = ( '' + seconds.toFixed(2) ).substr( -2 );
        timeStr += '.' + decimal;
      }

      return timeStr;
    };
  } ]);
