//
//  Book.h
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@interface Book : NSObject <AVAudioPlayerDelegate>
@property (nonatomic, readonly) NSString* identifier;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* author;
@property (nonatomic, readonly) NSArray* parts; // contains BookPart elements

// how many seconds to keep bufferingPoint ahead of position
@property (nonatomic, assign) NSTimeInterval bufferLookahead;

// Book should try to keep its buffer filled to this many seconds,
// whch can be set to very large number to buffer entire Book.
@property (nonatomic, assign) NSTimeInterval bufferingPoint;

// Like bufferingPoint but for data that is already present in cache
// Starts counting at current position and stops counting at first part of book
// not cached to the end.
@property (nonatomic, readonly) NSTimeInterval ensuredBufferingPoint;

-(void)play;
-(void)stop;

// position within books, either globally or by part
@property (nonatomic, assign) NSTimeInterval position;       // seeks when set
@property (nonatomic, assign) NSUInteger currentPart;
@property (nonatomic, assign) NSTimeInterval positionInPart; // position relative to start of current part

// used for debugging purposes and will adjust all URLS to get the given baseURL.
+(Book*)bookFromDictionary:(NSDictionary*)dictionary baseURL:(NSURL*)baseURL;

// bookFromDictionaries expects the following format:
//  {"id":37027, "author":"", "title":"Bunker 137",
//   "playlist": [{"url": "http://localhost:9000/DodpFiles/20254/37027/02_Om_denne_udgave.mp3",
//               "start": 1.599,
//               "end": 3.999}, ...],
//  "navigation": [{"title":"Michael Kamp: Bunker 137", "offset":0}, ...
// ]}
+(Book*)bookFromDictionary:(NSDictionary*)dictionary;

// used for debugging purposes and will adjust all URLS to get the given baseURL.
+(Book*)bookFromDictionary:(NSDictionary*)dictionary baseURL:(NSURL*)baseURL;

// try to make fewer parts by joining parts of book that are consecutive
-(void)joinParts;

// Queue player where items point directly to remote URLs and do no caching.
-(AVQueuePlayer*)makeQueuePlayer;

-(void)deleteCache;

@end
