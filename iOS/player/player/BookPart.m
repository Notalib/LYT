//
//  BookPart.m
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import "BookPart.h"

@implementation BookPart

-(NSString*)description {
    return [NSString stringWithFormat:@"%@ %.3f-%.3f", self.url.lastPathComponent, self.start, self.end];
}

@end
