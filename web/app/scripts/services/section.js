'use strict';

/**
 * @ngdoc service
 * @name lyt3App.Section
 * @description
 * # Section
 * Factory in the lyt3App.
 */
angular.module('lyt3App')
  .factory('Section', function () {
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
