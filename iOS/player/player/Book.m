//
//  Book.m
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import "Book.h"
#import "BookPart.h"
#import "debug.h"

@implementation Book

-(NSString*)description {
    return [NSString stringWithFormat:@"%@ %@: \n%@", self.title, self.author, self.parts];
}

-(void)dealloc {
    [self setParts:nil];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"bufferingsSatisfied"]) {
        BookPart* part = object;
        if(part.bufferingsSatisfied) {
            if(part.bufferingPoint > 0.0) {
                DBGLog(@"Buffering of %.1f seconds completed: %@", part.bufferingPoint, part);
            }
            
            [self cascadeBufferingPoint];
        }
    } else if([keyPath isEqualToString:@"error"]) {
        BookPart* part = object;
        NSError* error = part.error;
        if(error) {
            NSLog(@"%@ error: %@", part, error);
        }
    }
}

// we turn on KVO notifications for each part of book to know buffering status
-(void)setParts:(NSArray *)parts {
    if(parts == _parts) return;
    
    for (BookPart* part in _parts) {
        [part removeObserver:self forKeyPath:@"bufferingsSatisfied"];
        [part removeObserver:self forKeyPath:@"error"];
    }
    _parts = parts;
    for (BookPart* part in _parts) {
        [part addObserver:self forKeyPath:@"error" options:0 context:NULL];
        [part addObserver:self forKeyPath:@"bufferingsSatisfied" options:0 context:NULL];
    }
}

+(Book*)bookFromDictionary:(NSDictionary*)dictionary baseURL:(NSURL*)baseURL {
    NSArray* partDictionaries = [dictionary objectForKey:@"playlist"];
    NSMutableArray* parts = [NSMutableArray arrayWithCapacity:partDictionaries.count];
    for (NSDictionary* dictionary in partDictionaries) {
        NSString* url = [dictionary objectForKey:@"url"];
        NSNumber* start = [dictionary objectForKey:@"start"];
        NSNumber* end = [dictionary objectForKey:@"end"];
        
        NSURL* correctedUrl = [baseURL URLByAppendingPathComponent:url.lastPathComponent];
        
        BookPart* part = [BookPart new];
        part.start = start.doubleValue;
        part.end = end.doubleValue;
        part.url = correctedUrl;
        [parts addObject:part];
    }
    
    Book* book = [Book new];
    book.title = [dictionary objectForKey:@"title"];
    book.author = [dictionary objectForKey:@"author"];
    book.parts = parts;
    return book;
}

-(void)joinParts {
    NSMutableArray* array = [NSMutableArray new];
    BookPart* last = nil;
    for (BookPart* part in self.parts) {
        BookPart* joined = [last partCombinedWith: part];
        if(joined == nil) {
            // join not possible, add last part of needed
            if(last) [array addObject:last];
            last = part;            
        } else {
            // join was possible
            last = joined;
        }
    }
    if(last) [array addObject:last];
    
    self.parts = array;
}

-(AVQueuePlayer*)makeQueuePlayer:(BOOL)buffered {
    NSMutableArray* items = [NSMutableArray arrayWithCapacity:self.parts.count];
    for (BookPart* part in self.parts) {
        AVPlayerItem* playerItem = [part makePlayerItem: buffered];
        if(playerItem) {
            [items addObject: playerItem];
        }
    }
    
    AVQueuePlayer* player = [AVQueuePlayer queuePlayerWithItems: items];
    return player;
}

// buffering point should be cascaded to each part of the book, but
// we stop cascade on first book that have not fully buffered to avoid
// congesting buffering the next part of the book with later parts.
-(void)cascadeBufferingPoint {
    NSTimeInterval time = 0;
    for (BookPart* part in self.parts) {
        part.bufferingPoint = _bufferingPoint - time;
        time += part.end - part.start;
        
        if(!part.bufferingsSatisfied) break;
    }
}

-(void)setBufferingPoint:(NSTimeInterval)bufferingPoint {
    _bufferingPoint = bufferingPoint;
    [self cascadeBufferingPoint];
}

-(void)deleteCache {
    for (BookPart* part in self.parts) {
        [part deleteCache];
    }
}

@end
