//
//  BookPart.m
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "BookPart.h"

@implementation BookPart

-(NSString*)description {
    return [NSString stringWithFormat:@"%@ %.3f-%.3f", self.url.lastPathComponent, self.start, self.end];
}

-(BookPart*)partCombinedWith:(BookPart*)otherPart {
    // url's must match
    if(![self.url isEqual:otherPart.url]) return nil;
    
    // they must lie end-to-end
    if(self.end != otherPart.start) return nil;
    
    // join is allowed
    BookPart* joined = [BookPart new];
    joined.url = self.url;
    joined.start = self.start;
    joined.end = otherPart.end;
    return joined;
}

-(AVPlayerItem*)makePlayerItem {
    AVAsset* asset = [AVAsset assetWithURL:self.url];
    return [[AVPlayerItem alloc] initWithAsset:asset];
}

@end
