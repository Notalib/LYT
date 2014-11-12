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
@property (nonatomic, readonly) NSArray* parts; // contains BookPart elements

// used for debugging purposes, info is array of dictionaries such as:
//     {"url": "http://localhost:9000/DodpFiles/20254/37027/02_Om_denne_udgave.mp3",
//      "start": 1.599,
//      "end": 3.999}
// and baseURL is used to create workable URL's.
+(Book*)bookFromDictionaries:(NSArray*)dictionaries baseURL:(NSURL*)baseURL;

// try to make fewer parts by joining parts of book that are consecutive
-(void)joinParts;

-(AVQueuePlayer*)makeQueuePlayer;

@end
