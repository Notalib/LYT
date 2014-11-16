/*global jQuery: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'SMILDocument', [ 'LYTUtils', 'DtbDocument', 'Segment',
    function( LYTUtils, DtbDocument, Segment ) {
      var idCounts, parseMainSeqNode, parseNPT, parseParNode, parseTextNode;

      // ## Privileged

      // Parse the main `<seq>` element's `<par>`s
      // See [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi)
      parseMainSeqNode = function( sequence, smil, sections ) {
        var parData = [ ];
        var refs = sections.reduce( function( refs, section ) {
          refs[ section.fragment ] = section;
          return refs;
        }, {} );

        sequence.children( 'par' )
          .each( function( ) {
            parData = parData.concat( parseParNode( jQuery( this ) ) );
          } );

        var previous = null;
        var segments = parData.map( function( _segment, index ) {
          var sectionID;
          var segment = new Segment( _segment, smil );
          segment.index = index;
          segment.previous = previous;

          // Mark if this segment is beginning a new section
          if ( segment.id in refs ) {
            sectionID = segment.el.id;
          } else {
            segment.el.find( '[id]' )
              .each( function( ) {
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

          previous = segment;

          return segment;
        } );
        return segments;
      };

      // Parse a `<par>` node
      idCounts = {};
      parseParNode = function( par ) {
        var lastClip;
        // Find the `text` node, and parse it separately
        var text = parseTextNode( par.find( 'text:first' ) );

        // Find all nested `audio` nodes
        var clips = par.find( '> audio, seq > audio' )
          .map( function( ) {
            var audio = jQuery( this );
            return {
              id: par.attr( 'id' ) || ( '__LYT_auto_' + ( audio.attr(
                'src' ) ) + '_' + ( idCounts[ audio.attr( 'src' ) ] ++ ) ),
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
          return [ ];
        }

        // Collapse adjacent audio clips
        var reducedClips = [ ];
        clips.forEach( function( clip ) {
          if ( ( typeof lastClip !== 'undefined' && lastClip !== null ) &&
            clip.audio.src === lastClip.audio.src ) {
            // Ignore small differences between start and end,
            // since this can occur as a result of rounding errors
            if ( Math.abs( clip.start - lastClip.end ) < 0.001 ) {
              lastClip.end = clip.end;
              return;
            }
          }

          lastClip = clip;
          reducedClips.push( clip );
        } );
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
        var time = string.match( /^npt=([\d.]+)s?$/i );
        if ( time ) {
          return parseFloat( time[ 1 ], 10 );
        }
        return 0;
      };

      // Class to model a SMIL document
      function SMILDocument( url, book ) {
        DtbDocument.call( this, url, function( ) {
          var mainSequence = this.source.find(
            'body > seq:first' );

          this.book = book;
          this.duration = parseFloat( mainSequence.attr( 'dur' ) ) || 0;
          this.segments = parseMainSeqNode( mainSequence, this, book.nccDocument.sections );

          var totalElapsedTime = ( this.getMetadata( ).totalElapsedTime || {} ).content;
          this.absoluteOffset = LYTUtils.parseTime( totalElapsedTime ) || null;

          this.filename = this.url.split( '/' ).pop( );

        }.bind( this ) );
      }

      SMILDocument.prototype = Object.create( DtbDocument.prototype );

      SMILDocument.prototype.getSegmentById = function( id ) {
        var res = null;
        this.segments.some( function( segment ) {
          if ( segment.id === id ) {
            res = segment;
            return true;
          }
        } );

        return res;
      };

      SMILDocument.prototype.getContainingSegment = function( id ) {
        var segment = this.getSegmentById( id );
        if ( segment ) {
          return segment;
        }

        this.segments.some( function( _segment ) {
          if ( _segment.el.find( '#' + id ).length > 0 ) {
            segment = _segment;
            return true;
          }
        } );

        return segment;
      };

      SMILDocument.prototype.getSegmentAtOffset = function( offset ) {
        var segment = null;
        if ( !offset ) {
          offset = 0;
        }

        if ( offset < 0 ) {
          offset = 0;
        }

        this.segments.some( function( _segment ) {
          if ( _segment.start <= offset && offset < _segment.end ) {
            segment = _segment;
            return true;
          }
        } );

        return segment;
      };

      SMILDocument.prototype.getAudioReferences = function( ) {
        var urls = [ ];

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
        if ( id1 === id2 ) {
          return 0;
        }
        var seg1 = this.getSegmentById( id1 );
        var seg2 = this.getSegmentById( id2 );

        var res;
        this.segments.some( function( segment ) {
          if ( segment.id === seg1.id ) {
            res = -1;
            return true;
          } else if ( segment.id === seg2.id ) {
            res = 1;
            return true;
          }
        } );

        return res;
      };

      return SMILDocument;
    }
  ] );
