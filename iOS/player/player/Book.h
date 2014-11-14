//
//  Book.h
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@interface Book : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* author;
@property (nonatomic, readonly) NSArray* parts; // contains BookPart elements

// Book should try to keep its buffer filled to this many seconds,
// whch can be set to very large number to buffer entire Book.
@property (nonatomic, assign) NSTimeInterval bufferingPoint;

// used for debugging purposes, info is array of dictionaries such as:
// bookFromDictionaries expects the following format:
// {"id":37027, "author":"", "title":"Bunker 137",
// "playlist": [{"url": "http://localhost:9000/DodpFiles/20254/37027/02_Om_denne_udgave.mp3",
//               "start": 1.599,
//               "end": 3.999}, ...],
// "navigation": [{"title":"Michael Kamp: Bunker 137", "offset":0}, ...
// ]}
+(Book*)bookFromDictionary:(NSDictionary*)dictionary baseURL:(NSURL*)baseURL;

// try to make fewer parts by joining parts of book that are consecutive
-(void)joinParts;

-(AVQueuePlayer*)makeQueuePlayer:(BOOL)buffered;

-(void)deleteCache;

@end
