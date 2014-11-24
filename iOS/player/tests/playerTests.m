//
//  playerTests.m
//  playerTests
//
//  Created by Anders Borum on 11/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Book.h"

@interface playerTests : XCTestCase {
    NSURL* baseURL;
}

@end

@implementation playerTests

- (void)setUp {
    [super setUp];

    // TODO: Right now we need to edit baseURL by hand, but to make repeatable tests we
    // need some way to obtain replacement fior second to last number (20008).
    baseURL = [NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20008/37027/"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

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

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
