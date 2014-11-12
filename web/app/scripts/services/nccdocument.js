/*global jQuery: false */
'use strict';

/**
 * @ngdoc service
 * @name lyt3App.NCCDocument
 * @description
 * # NCCDocument
 * Factory in the lyt3App.
 */
angular.module( 'lyt3App' )
  .factory( 'NCCDocument', [ '$q', 'TextContentDocument', 'Section',
    function( $q, TextContentDocument, Section ) {
      var flattenStructure, linkSections, parseStructure;

      // ## Privileged

      // Internal helper function to parse the (flat) heading structure of an NCC document
      // into a nested collection of `NCCSection` objects
      parseStructure = function( xml, book ) {
        /*
         * Collects consecutive heading of the given level or higher in the `collector`.
         * I.e. given a level of 3, it will collect all `H3` elements until it hits an `H1`
         * element. Each higher level (i.e. `H4`) heading encountered along the way will be
         * collected recursively.
         * Returns the number of headings collected.
         * FIXME: Doesn't take changes in level with more than one into account, e.g. from h1 to h3.
         */
        var getConsecutive, headings, level, markMetaSections, numberSections, structure;
        getConsecutive = function( headings, level, collector ) {
          var heading, index, section;
          index = 0;
          // Loop through the `headings` array
          while ( headings.length > index ) {
            heading = headings[ index ];
            if ( heading.tagName.toLowerCase() !== ( 'h' + level ) ) {
              // Return the current index if the heading isn't the given level
              return index;
            }

            // Create a section object
            section = new Section( heading, book );
            section.parent = level - 1;
            // Collect all higher-level headings into that section's `children` array,
            // and increment the `index` accordingly
            index += getConsecutive( headings.slice( index + 1 ), level + 1, section.children );
            // Add the section to the collector array
            collector.push( section );
            index++;
          }

          // If the loop ran to the end of the `headings` array, return the array's length
          return headings.length;
        };
        // TODO: See if we can remove this, since all sections are being addressed
        // using URLs
        numberSections = function( sections, prefix ) {
          var index, number, section, _i, _len, _results;
          if ( !prefix ) {
            prefix = '';
          }
          if ( prefix ) {
            prefix = '' + prefix + '.';
          }
          _results = [];
          for ( index = _i = 0, _len = sections.length; _i < _len; index = ++_i ) {
            section = sections[ index ];
            number = '' + prefix + ( index + 1 );
            section.id = number;
            _results.push( numberSections( section.children, number ) );
          }
          return _results;
        };
        markMetaSections = function( sections ) {
          var isBlacklisted, metaSectionList, section, _i, _len, _results;
          // TODO: metaSectionList = LYT.config.nccDocument.metaSections;
          metaSectionList = {};
          isBlacklisted = function( section ) {
            var type, value;
            for ( value in metaSectionList ) {
              type = metaSectionList[ value ];
              if ( section[ type ] === value ) {
                return true;
              }
            }
            return false;
          };
          _results = [];
          for ( _i = 0, _len = sections.length; _i < _len; _i++ ) {
            section = sections[ _i ];
            if ( isBlacklisted( section ) ) {
              section.metaContent = true;
            }
            if ( section.children.length ) {
              _results.push( markMetaSections( section.children ) );
            } else {
              _results.push( void 0 );
            }
          }
          return _results;
        };
        structure = [];

        // Find all headings as a plain array
        headings = jQuery.makeArray( xml.find( ':header' ) );
        if ( headings.length === 0 ) {
          return [];
        }

        // Find the level of the first heading (should be level 1)
        level = parseInt( headings[ 0 ].tagName.slice( 1 ), 10 );

        // Get all consecutive headings of that level
        getConsecutive( headings, level, structure );

        // Mark all meta sections so we don't play them per default
        markMetaSections( structure );

        // Number sections
        numberSections( structure );
        return structure;
      };
      flattenStructure = function( structure ) {
        var flat, section, _i, _len;
        flat = [];
        for ( _i = 0, _len = structure.length; _i < _len; _i++ ) {
          section = structure[ _i ];
          flat.push( section );
          flat = flat.concat( flattenStructure( section.children ) );
        }
        return flat;
      };
      // Initializes previous and next attributes on section objects
      linkSections = function( sections ) {
        var previous, section, _i, _len, _results;
        previous = null;
        _results = [];
        for ( _i = 0, _len = sections.length; _i < _len; _i++ ) {
          section = sections[ _i ];
          section.previous = previous;
          if ( previous ) {
            previous.next = section;
          }
          _results.push( previous = section );
        }
        return _results;
      };

      /*
       * This class models a Daisy Navigation Control Center document
       * FIXME: Don't carry the @sections array around. @structure should be used.
       *        At the same time, the flattenStructure procedure can be replaced by
       *        an extension of the getConsecutive procedure that does the linking
       *        handled by flattenStructure followed by linkSections.
       */
      function NCCDocument( url, book ) {
        this.getSectionByURL = this.getSectionByURL.bind( this );
        TextContentDocument.call( this, url, book.resources, ( function( _this ) {
          return function() {
            var section, _i, _len, _ref, _results;
            _this.structure = parseStructure( _this.source, book );
            _this.sections = flattenStructure( _this.structure );
            linkSections( _this.sections );
            _ref = _this.sections;
            _results = [];
            for ( _i = 0, _len = _ref.length; _i < _len; _i++ ) {
              section = _ref[ _i ];
              _results.push( section.nccDocument = _this );
            }
            return _results;
          };
        } )( this ) );
      }

      NCCDocument.prototype = Object.create( TextContentDocument.prototype );

      /*
       * The section getters below returns promises that wait for the section
       * resources to load.

       * Helper function for section getters
       * Return a promise that ensures that resources for both this object
       * and the section are loaded.
       */
      NCCDocument.prototype._getSection = function( getter ) {
        var deferred = $q.defer();
        this.promise.catch( function() {
          return deferred.reject();
        } );
        this.promise.then( function( document ) {
          var section = getter( document.sections );
          if ( section ) {
            section.load();
            section.promise.then( function() {
              deferred.resolve( section );
            } );
            section.promise.catch( function() {
              deferred.reject();
            } );
          } else {
            deferred.reject();
          }
        } );
        return deferred.promise;
      };

      NCCDocument.prototype.firstSection = function() {
        return this._getSection( function( sections ) {
          return sections[ 0 ];
        } );
      };

      NCCDocument.prototype.getSectionByURL = function( url ) {
        var baseUrl = url.split( '#' )[ 0 ];
        return this._getSection( function( sections ) {
          sections.forEach(function(section){
            if ( section.url === baseUrl ) {
              return section;
            }
          });
        } );
      };

      NCCDocument.prototype.getSectionIndexById = function( id ) {
        var i, section, _i, _len, _ref;
        _ref = this.sections;
        for ( i = _i = 0, _len = _ref.length; _i < _len; i = ++_i ) {
          section = _ref[ i ];
          if ( section.id === id ) {
            return i;
          }
        }
      };

      return NCCDocument;

    }
  ] );
