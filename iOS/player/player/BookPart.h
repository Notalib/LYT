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

// start and end are meased in seconds
@property (nonatomic, assign) NSTimeInterval start;
@property (nonatomic, assign) NSTimeInterval end;

@end
