//
//  BookPart.h
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BookPart : NSObject
@property (nonatomic, strong) NSURL* url;

// start and end are measured in seconds
@property (nonatomic, assign) NSTimeInterval start;
@property (nonatomic, assign) NSTimeInterval end;

// BookPart should try to keep its buffer filled to this many seconds,
// whch can be set to very large number to buffer entire BookPart.
@property (nonatomic, assign) NSTimeInterval bufferingPoint;

// return BookPart that combines self and otherPart returning nil
// if join is not possible. To be joinable the url's must
// match and self must end where otherPart starts.
-(BookPart*)partCombinedWith:(BookPart*)otherPart;

-(AVPlayerItem*)makePlayerItem;

-(void)deleteCache;

@end
