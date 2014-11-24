//
//  tests.m
//  tests
//
//  Created by Anders Borum on 24/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Book.h"

@interface tests : XCTestCase {
    NSURL* baseURL;
}

@end

@implementation tests

-(void)testJSONFragments {
    NSString* json = @"[\"37027\"]";
    
    json = [json stringByReplacingOccurrencesOfString:@"^\\s*\\[" withString:@""
                                              options:NSRegularExpressionSearch range:NSMakeRange(0, json.length)];
    XCTAssertTrue([json isEqualToString: @"\"37027\"]"]);
    
    // remove trailing ]
    json = [json stringByReplacingOccurrencesOfString:@"\\]\\s*$" withString:@""
                                              options:NSRegularExpressionSearch range:NSMakeRange(0, json.length)];
    XCTAssertTrue([json isEqualToString: @"\"37027\""]);
}

-(void)testReadBook {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"37027.json" ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile:path];
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    XCTAssertNotNil(json);
    
    Book* book = [Book bookFromDictionary:json baseURL:baseURL];
    NSLog(@"book = %@", book);
    XCTAssertNotNil(book);
    XCTAssertTrue(book.parts.count >= 1);
    
    [book joinParts];
    NSLog(@"joined book = %@", book);
    XCTAssertTrue(book.parts.count >= 1);
}

@end
