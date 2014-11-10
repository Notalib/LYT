'use strict';

/**
 * @ngdoc service
 * @name lyt3App.Segment
 * @description
 * # Segment
 * Factory in the lyt3App.
 */
angular.module('lyt3App')
  .factory('Segment', function () {
    // Service logic
    // ...

    var meaningOfLife = 42;

    // Public API here
    return {
      someMethod: function () {
        return meaningOfLife;
      }
    };
  });
