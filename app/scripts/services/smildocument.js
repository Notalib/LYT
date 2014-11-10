'use strict';

/**
 * @ngdoc service
 * @name lyt3App.SMILDocument
 * @description
 * # SMILDocument
 * Factory in the lyt3App.
 */
angular.module('lyt3App')
  .factory('SMILDocument', function () {
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
