'use strict';

/**
 * @ngdoc service
 * @name lyt3App.BookErrorCodes
 * @description
 * # BookErrorCodes
 * Factory in the lyt3App.
 */
angular.module('lyt3App')
  .factory('BookErrorCodes', function () {
    var BOOK_ISSUE_CONTENT_ERROR = {};

    var BOOK_CONTENT_RESOURCES_ERROR = {};

    var BOOK_NCC_NOT_FOUND_ERROR = {};

    var BOOK_NCC_NOT_LOADED_ERROR = {};

    var BOOK_BOOKMARKS_NOT_LOADED_ERROR = {};

    return {
      get BOOK_ISSUE_CONTENT_ERROR() {
        return BOOK_ISSUE_CONTENT_ERROR;
      },
      get BOOK_CONTENT_RESOURCES_ERROR() {
        return BOOK_CONTENT_RESOURCES_ERROR;
      },
      get BOOK_NCC_NOT_FOUND_ERROR() {
        return BOOK_NCC_NOT_FOUND_ERROR;
      },
      get BOOK_NCC_NOT_LOADED_ERROR() {
        return BOOK_NCC_NOT_LOADED_ERROR;
      },
      get BOOK_BOOKMARKS_NOT_LOADED_ERROR() {
        return BOOK_BOOKMARKS_NOT_LOADED_ERROR;
      }
    };
  });
