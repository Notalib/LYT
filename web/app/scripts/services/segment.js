/*global $: false */
'use strict';

angular.module( 'lyt3App' )
  .factory( 'Segment', [ '$q', 'TextContentDocument', 'Bookmark',
    function( $q, TextContentDocument, Bookmark ) {
      /*
       * This class models a 'segment' of audio + transcript,
       * i.e. a single 'sound clip' and its associated text/html
       *
       * A Segment instance is a Deferred. It resolves when all
       * images contained in the transcript have been loaded (by
       * calling the `preload` method), or if there were no images
       * to load.
       *
       * A Segment instance has the following properties:
       *
       * - id:              The id of the <par> element in the SMIL document
       * - start:           The start time, in seconds, relative to the audio
       * - end:             The end time, in seconds, relative to the audio
       * - audio:           The url of the audio file (or null)
       * - text:            The text content of the HTML content (or null)
       * - type:            Type of this segment. The following two types are
       *                    currently supported:
       *                     - cartoon:  Display one large image.
       *                                 Each segment is an area that the
       *                                 player should pan and zoom to.
       *                     - standard: Displays the provided content, replacing
       *                                 any previous content.
       * And the following methods (not in prototype, mixed-in in constructor):
       *
       * - preload:         Preloads transcript content (i.e. images).
       * - state:           This is the state of the `Deferred#promise` used to indicate
       *                    if the segment has been loaded yet:
       *                     - pending:  the load() method hasn't been called yet
       *                                 or the segment is currently loading.
       *                     - resolved: the segment has been loaded and can be
       *                                 displayed.
       *                     - rejected: loading the segment has failed.
       */
      function Segment( data, document ) {
        // Set up deferred load of images
        this._deferred = $q.defer( );
        this.promise = this._deferred.promise;
        this.promise.then( function( ) {
          this.ready = true;
        }.bind( this ) );

        // Properties initialized in the constructor
        this.id = data.id;
        this.index = data.index;
        this.start = data.start;
        this.end = data.end;
        this.canBookmark = data.canBookmark;
        this.audio = void 0;
        if ( data.audio && data.audio.src ) {
          var src = data.audio.src.toLowerCase( );
          if ( document.book.resources[ src ] ) {
            this.audio = document.book.resources[ src ];
          }
        }
        this.data = data;
        this.el = data.par;
        this.document = document;

        // Will be initialized in the load() method:
        this.text = null;
        this.smil = data.smil;
      }

      // Loads all resources
      Segment.prototype.load = function( ) {
        var promise, resource, resources, _ref;
        // Skip if already finished
        if ( this.loading || this.loaded ) {
          return this.promise;
        }
        this.loading = true;
        this.promise.finally( ( function( _this ) {
          return function( ) {
            _this.loading = false;
            _this.loaded = true;
          };
        } )( this ) );
        this.promise.catch( ( function( _this ) {
          return function( ) {
            // TODO: log.error('Segment: failed loading segment ' + (_this.url()));
            console.log.error( 'Segment: failed loading segment ' +
              ( _this.url( ) ) );
          };
        } )( this ) );
        // log.message('Segment: loading ' + (this.url()));
        // Parse transcript content
        _ref = this.data.text.src.split( '#' );
        this.contentUrl = _ref[ 0 ];
        this.contentId = _ref[ 1 ];
        resources = this.document.book.resources;
        resource = resources[ this.contentUrl.toLowerCase( ) ];
        if ( !resource ) {
          // log.error('Segment: no absolute URL for content ' + this.contentUrl);
          this._deferred.reject( );
        } else {
          if ( !resource.document ) {
            resource.document = new TextContentDocument( resource.url,
              resources );
          }

          promise = resource.document.promise.then( ( function( _this ) {
            return function( document ) {
              return _this.parseContent( document );
            };
          } )( this ) );

          promise.then( ( function( _this ) {
            return function( ) {
              return _this._deferred.resolve( _this );
            };
          } )( this ) );

          promise.catch( ( function( _this ) {
            return function( status, error ) {
              // TODO: log.error('Unable to get TextContentDocument for ' + resource.url + ': ' + status + ', ' + error);
              console.log.error(
                'Unable to get TextContentDocument for ' +
                resource.url + ': ' + status + ', ' + error );
              return _this._deferred.reject( );
            };
          } )( this ) );
        }
        return this.promise;
      };

      Segment.prototype.url = function( ) {
        return '' + this.document.filename + '#' + this.id;
      };

      Segment.prototype.ready = false;

      Segment.prototype.hasNext = function( ) {
        return !!this.next;
      };

      Segment.prototype.hasPrevious = function( ) {
        return !!this.previous;
      };

      Segment.prototype.getNext = function( ) {
        return this.next;
      };

      Segment.prototype.getPrevious = function( ) {
        return this.previous;
      };

      Segment.prototype.duration = function( ) {
        return this.end - this.start;
      };

      Segment.prototype.search = function( iterator, filter, onlyOne ) {
        var item, result;
        if ( onlyOne === undefined ) {
          onlyOne = true;
        }
        if ( onlyOne ) {
          while ( ( item = iterator( ) ) ) {
            if ( filter( item ) ) {
              return item;
            }
          }
        } else {
          result = [ ];
          while ( ( item = iterator( ) ) ) {
            if ( filter( item ) ) {
              result.push( item );
            }
          }
          return result;
        }
      };

      Segment.prototype.searchBackward = function( filter, onlyOne ) {
        var current, iterator;
        current = this;
        iterator = function( ) {
          current = current.previous;
          return current;
        };
        return this.search( iterator, filter, onlyOne );
      };

      Segment.prototype.searchForward = function( filter, onlyOne ) {
        var current, iterator;
        current = this;
        iterator = function( ) {
          current = current.next;
          return current;
        };
        return this.search( iterator, filter, onlyOne );
      };

      Segment.prototype.bookmark = function( audioOffset ) {
        return new Bookmark( {
          URI: this.url( ),
          timeOffset: this.smilOffset( audioOffset )
        } );
      };

      Segment.prototype.smilStart = function( ) {
        var segment, start;
        if ( this.smil.start !== undefined ) {
          return this.smil.start;
        }
        start = 0;
        segment = this;
        while ( ( segment = segment.previous ) ) {
          start += segment.duration( );
        }
        this.smil.start = start;
        return start;
      };

      // Convert from smil offset to audio offset
      Segment.prototype.audioOffset = function( smilOffset ) {
        return this.start + smilOffset - this.smilStart( );
      };

      // Convert from audio offset to smil offset
      Segment.prototype.smilOffset = function( audioOffset ) {
        return this.smilStart( ) + audioOffset - this.start;
      };

      Segment.prototype.containsSmilOffset = function( smilOffset ) {
        return ( this.smilStart( ) <= smilOffset && smilOffset <= this.smilStart( ) +
          this.duration( ) );
      };

      Segment.prototype.containsOffset = function( offset ) {
        return ( this.start <= offset && offset <= this.end );
      };

      // Will load this segment and the next preloadCount segments
      Segment.prototype.preloadNext = function( preloadCount ) {
        if ( preloadCount === undefined ) {
          // TODO: preloadCount = LYT.config.segment.preload.queueSize;
          preloadCount = 10;
        }

        this.load( );
        if ( preloadCount === 0 ) {
          return;
        }

        return this.promise.then( ( function( _this ) {
          return function( segment ) {
            var next = segment.next,
              nextSection;
            if ( next ) {
              return next.preloadNext( preloadCount - 1 );
            } else {
              var segmentSection = _this.document.book.getSectionBySegment(
                segment );
              if ( segmentSection ) {
                nextSection = segmentSection.next;
              }

              if ( nextSection ) {
                return nextSection.firstSegment( )
                  .promise.then( function( next ) {
                    return next.preloadNext( preloadCount - 1 );
                  } );
              }
            }
          };
        } )( this ) );
      };

      // Parse content document and extract segment data
      // Used with deferreds, so should return this (the segment itself) or a failed
      // promise in order to reject processing.
      Segment.prototype.parseContent = function( document ) {
        var getCanvasScale, getCanvasSize, image, imageData, loadImage,
          source, sourceContent;
        source = document.source;
        sourceContent = source.find( '#' + this.contentId );
        if ( sourceContent.parent( )
          .hasClass( 'page' ) && sourceContent.is( 'div' ) && ( image =
            sourceContent.parent( )
            .children( 'img' ) ) ) {
          this.type = 'cartoon';
          getCanvasSize = function( image ) {
            var result = {};
            [ 'height', 'width' ].forEach( function( type ) {
              var dim = image.attr( type );
              if ( dim ) {
                result[ type ] = dim;
                return;
              }
              dim = image.attr( 'style' )
                .match( type + '\\s*:\\s*(\\d+)\\s*px' );
              if ( dim ) {
                result[ type ] = dim[ 1 ];
                return;
              }
              if ( image.parent( )
                .css( type )
                .match( /(\d+)(?:px)?/ ) ) {
                result[ type ] = dim[ 1 ];
                return;
              } else {
                var attr = type.replace( /^([a-z])/g, function( m, p1 ) {
                  return 'natural' + p1.toUpperCase( );
                } );
                // log.warn('render.content: imageDim: no ' + type + ' attribute or css ' + type + ' on image. Falling back to ' + attr + ' which is not known to be cross browser');
                result[ type ] = image[ attr ];
              }
            } );
            return result;
          };
          getCanvasScale = function( canvasSize, imageSize ) {
            var e;
            if ( canvasSize.width !== imageSize.width ) {
              try {
                return imageSize.width / canvasSize.width;
              } catch ( _error ) {
                e = _error;
                return 1;
              }
            } else {
              return 1;
            }
          };
          loadImage = ( function( /*_this*/ ) {
            return function( image ) {
              var doneHandler, errorHandler, tmp;
              // log.message('Segment: ' + (_this.url()) + ': parseContent: initiate preload of image ' + image.src);
              errorHandler = function( event ) {
                var backoff, doLoad;
                clearTimeout( image.timer );
                if ( image.attempts-- > 0 ) {
                  // TODO: backoff = Math.ceil(Math.exp(LYT.config.segment.imagePreload.attempts - image.attempts + 1) * 50);
                  backoff = 10;
                  // log.message('Segment: parseContent: preloading image ' + image.src + ' failed, ' + image.attempts + ' attempts left. Waiting for ' + backoff + ' ms.');
                  doLoad = function( ) {
                    return loadImage( image );
                  };
                  return setTimeout( doLoad, backoff );
                } else {
                  // log.error('Segment: parseContent: unable to preload image ' + image.src);
                  return image.deferred.reject( image, event );
                }
              };
              doneHandler = function( event ) {
                clearTimeout( image.timer );
                // log.message('Segment: parseContent: loaded image ' + image.src);
                return image.deferred.resolve( image, event );
              };
              image.timer = setTimeout( errorHandler, /*LYT.config.segment.imagePreload.timeout*/
                2500 );
              tmp = new Image( );
              $( tmp )
                .load( doneHandler )
                .error( errorHandler );
              tmp.src = image.src;
            };
          } )( this );

          if ( image.length !== 1 ) {
            // log.error('Segment: parseContent: can\'t create reliable cartoon type ' + ('with multiple or zero images: ' + (this.url())));
            throw 'Segment: parseContent: unable to find exactly one image in ' +
            'cartoon display div';
          }
          this.image = image.clone( )
            .wrap( '<p>' )
            .parent( )
            .html( );
          this.div = sourceContent.clone( )
            .wrap( '<p>' )
            .parent( )
            .html( );
          this.canvasSize = getCanvasSize( image );
          var imageDefer = $q.defer( );
          var imagePromise = imageDefer.promise;
          imageData = {
            src: image.attr( 'src' ),
            element: image[ 0 ],
            // TODO: attempts: LYT.config.segment.imagePreload.attempts,
            attempts: 10,
            deferred: imageDefer
          };
          imagePromise.done( ( function( _this ) {
            return function( imageData, event ) {
              _this.canvasScale = getCanvasScale( _this.canvasSize, {
                width: event.target.width,
                height: event.target.height
              } );
            };
          } )( this ) );
          loadImage( imageData );
          imagePromise.done( ( function( _this ) {
            return function( ) {
              // log.group('Segment: ' + (_this.url()) + ' finished extracting text, html and loading images', _this.text, image);
              return _this;
            };
          } )( this ) );

          return imagePromise;
        } else {
          this.type = 'standard';
        }
        return $q.defer( )
          .resolve( );
      };

      Segment.prototype.getBookOffset = function( ) {
        if ( !this.document ) {
          return 0;
        }

        return this.document.absoluteOffset + this.smilStart( );
      };

      return Segment;
    }
  ] );
