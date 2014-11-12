//
//  Book.m
//  player
//
//  Created by Anders Borum on 12/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import "Book.h"
#import "BookPart.h"

@implementation Book

+(Book*)bookFromDictionaries:(NSArray*)dictionaries baseURL:(NSURL*)baseURL {
    NSMutableArray* parts = [NSMutableArray arrayWithCapacity:dictionaries.count];
    for (NSDictionary* dictionary in dictionaries) {
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
    book->_parts = parts;
    return book;
    
}
@end
