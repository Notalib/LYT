'use strict';

describe('Filter: sec2time', function() {

  // load the filter's module
  beforeEach(module('lyt3App'));

  // initialize a new instance of the filter before each test
  var sec2time;
  beforeEach(inject( function( $filter ) {
    sec2time = $filter('sec2time');
  }));

  // testData:
  // time in secs => [ formatted time without decimals, formatted time with decimals ]
  var testData = {
    0: [ '0:00:00', '0:00:00.00' ],
    0.1: [ '0:00:00', '0:00:00.10' ],
    61.01: [ '0:01:01', '0:01:01.01' ],
    1000.51: [ '0:16:40', '0:16:40.51' ],
    28871.99: [ '8:01:11', '8:01:11.99' ],
  };

  it('should return the input prefixed with "sec2time filter:"', function() {
    Object.keys( testData ).forEach( function( seconds ) {
      var expectedOutput = testData[ seconds ];

      expect(sec2time(seconds)).toBe( expectedOutput[0] );
      expect(sec2time(seconds, true)).toBe( expectedOutput[1] );
    } );
  });

});
