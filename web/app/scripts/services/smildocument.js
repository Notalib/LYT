/*global jQuery: false */
'use strict';

/**
 * @ngdoc service
 * @name lyt3App.SMILDocument
 * @description
 * # SMILDocument
 * Factory in the lyt3App.
 */
angular.module( 'lyt3App' )
  .factory( 'SMILDocument', [ 'DtbDocument', 'Segment',
    function( DtbDocument, Segment ) {
      var idCounts, parseMainSeqNode, parseNPT, parseParNode, parseTextNode;

      // ## Privileged

      // Parse the main `<seq>` element's `<par>`s
      // See [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi)
      parseMainSeqNode = function( sequence, smil, sections ) {
        var parData, previous, refs, sectionID, segment, segments;
        segments = [];
        parData = [];
        refs = {};
        sections.forEach( function( section ) {
          refs[ section.fragment ] = section;
        } );
        sequence.children( 'par' )
          .each( function() {
            parData = parData.concat( parseParNode( jQuery( this ) ) );
          } );
        previous = null;
        parData.forEach( function( _segment, index ) {
          segment = new Segment( _segment, smil );
          segment.index = index;
          segment.previous = previous;

          // Mark if this segment is beginning a new section
          if ( segment.id in refs ) {
            sectionID = segment.el.id;
          } else {
            segment.el.find( '[id]' )
              .each( function() {
                var childID = this.getAttribute( 'id' );
                if ( childID in refs ) {
                  sectionID = childID;
                  return false;
                }
              } );
          }
          if ( sectionID ) {
            segment.beginSection = refs[ sectionID ];
            sectionID = null;
          }
          if ( previous ) {
            previous.next = segment;
          }
          segments.push( segment );
          previous = segment;
        } );
        return segments;
      };

      // Parse a `<par>` node
      idCounts = {};
      parseParNode = function( par ) {
        var clip, clips, i, lastClip, reducedClips, text;
        // Find the `text` node, and parse it separately
        text = parseTextNode( par.find( 'text:first' ) );

        // Find all nested `audio` nodes
        clips = par.find( '> audio, seq > audio' )
          .map( function() {
            var audio;
            audio = jQuery( this );
            return {
              id: par.attr( 'id' ) || ( '__LYT_auto_' + ( audio.attr( 'src' ) ) + '_' + ( idCounts[ audio.attr( 'src' ) ]++ ) ),
              start: parseNPT( audio.attr( 'clip-begin' ) ),
              end: parseNPT( audio.attr( 'clip-end' ) ),
              text: text,
              canBookmark: !!par.attr( 'id' ),
              audio: {
                src: audio.attr( 'src' )
              },
              smil: {
                element: audio
              },
              par: par
            };
          } );
        clips = jQuery.makeArray( clips );
        if ( clips.length === 0 ) {
          return [];
        }
        // Collapse adjacent audio clips
        reducedClips = [];
        i = 0;
        while ( ( clip = clips[ i ] ) ) {
          i++;
          if ( ( typeof lastClip !== 'undefined' && lastClip !== null ) && clip.audio.src === lastClip.audio.src ) {
            // Ignore small differences between start and end,
            // since this can occur as a result of rounding errors
            if ( Math.abs( clip.start - lastClip.end ) < 0.001 ) {
              lastClip.end = clip.end;
              continue;
            }
          }
          lastClip = clip;
          reducedClips.push( clip );
        }
        return reducedClips;
      };
      parseTextNode = function( text ) {
        if ( text.length === 0 ) {
          return null;
        }
        return {
          id: text.attr( 'id' ),
          src: text.attr( 'src' )
        };
      };
      // Parse the Normal Play Time format (npt=ss.s)
      // See [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi)
      parseNPT = function( string ) {
        var time;
        time = string.match( /^npt=([\d.]+)s?$/i );
        if ( time ) {
          return parseFloat( time[ 1 ], 10 );
        }
        return 0;
      };

      // Class to model a SMIL document
      function SMILDocument( url, book ) {
        DtbDocument.call( this, url, ( function( _this ) {
          return function() {
            var mainSequence = _this.source.find( 'body > seq:first' );
            _this.book = book;
            _this.duration = parseFloat( mainSequence.attr( 'dur' ) ) || 0;
            _this.segments = parseMainSeqNode( mainSequence, _this, book.nccDocument.sections );
            // TODO: _this.absoluteOffset = LYT.utils.parseTime((_ref = _this.getMetadata().totalElapsedTime) != null ? _ref.content : void 0) || null;
            _this.filename = _this.url.split( '/' )
              .pop();
          };
        } )( this ) );
      }

      SMILDocument.prototype = Object.create( DtbDocument.prototype );

      SMILDocument.prototype.getSegmentById = function( id ) {
        var index, segment, _i, _len, _ref;
        _ref = this.segments;
        for ( index = _i = 0, _len = _ref.length; _i < _len; index = ++_i ) {
          segment = _ref[ index ];
          if ( segment.id === id ) {
            return segment;
          }
        }
        return null;
      };

      SMILDocument.prototype.getContainingSegment = function( id ) {
        var index, segment, _i, _len, _ref;
        segment = this.getSegmentById( id );
        if ( segment ) {
          return segment;
        }
        _ref = this.segments;
        for ( index = _i = 0, _len = _ref.length; _i < _len; index = ++_i ) {
          segment = _ref[ index ];
          if ( segment.el.find( '#' + id )
            .length > 0 ) {
            return segment;
          }
        }
        return null;
      };

      SMILDocument.prototype.getSegmentAtOffset = function( offset ) {
        var index, segment, _i, _len, _ref;
        if ( !offset ) {
          offset = 0;
        }
        if ( offset < 0 ) {
          offset = 0;
        }
        _ref = this.segments;
        for ( index = _i = 0, _len = _ref.length; _i < _len; index = ++_i ) {
          segment = _ref[ index ];
          if ( ( segment.start <= offset && offset < segment.end ) ) {
            return segment;
          }
        }
        return null;
      };

      SMILDocument.prototype.getAudioReferences = function() {
        var urls = [];
        this.segments.forEach( function( segment ) {
          if ( segment.audio.src ) {
            if ( urls.indexOf( segment.audio.src ) === -1 ) {
              urls.push( segment.audio.src );
            }
          }
        } );
        return urls;
      };

      SMILDocument.prototype.orderSegmentsByID = function( id1, id2 ) {
        var seg1, seg2, segment, _i, _len, _ref;
        if ( id1 === id2 ) {
          return 0;
        }
        seg1 = this.getSegmentById( id1 );
        seg2 = this.getSegmentById( id2 );
        _ref = this.segments;
        for ( _i = 0, _len = _ref.length; _i < _len; _i++ ) {
          segment = _ref[ _i ];
          if ( segment.id === seg1.id ) {
            return -1;
          } else if ( segment.id === seg2.id ) {
            return 1;
          }
        }
      };

      return SMILDocument;
    }
  ] );
