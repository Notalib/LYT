'use strict';

angular.module('lyt3App')
  .filter('sec2time', [ 'LYTUtils', function( LYTUtils ) {
    return function( seconds, includeSecondsDecimal ) {
      var timeStr = LYTUtils.formatTime(seconds);

      if ( includeSecondsDecimal ) {
        var decimal = ( '0' + Math.ceil( ( seconds - Math.floor( seconds ) ) * 100 ) ).substr( -2 );
        timeStr += '.' + decimal;
      }

      return timeStr;
    };
  } ]);
