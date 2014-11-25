//
//  BookPartTests.m
//  player
//
//  Created by Anders Borum on 25/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BookPart.h"

// Must be set manually by opening a browser on the same IP address as the tests should run
// going to URL:
//    http://m.e17.dk/#bookshelf
// and start playback and look for requests on the form:
//    http://m.e17.dk/DodpFiles/20008/37027/02_Om_denne_udgave.mp3
//                              ^^^^^
//                           LYT_USER_ID
#define LYT_USER_ID 20008

@interface bookPartTests : XCTestCase {
    NSURL* baseURL;
}

@end

@implementation bookPartTests

- (void)setUp {
    [super setUp];

    baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://m.e17.dk/DodpFiles/%d/", LYT_USER_ID]];
}

-(void)testDownload {
    BookPart* part = [BookPart new];
    part.url = [NSURL URLWithString:@"37027/02_Om_denne_udgave.mp3" relativeToURL:baseURL];
    [part deleteCache];
    part.end = 5;
    part.bufferingPoint = part.end;
    
    // we want buffering to complete within 10 seconds
    XCTAssertFalse(part.bufferingsSatisfied);
    [self keyValueObservingExpectationForObject:part keyPath:@"bufferingsSatisfied"
                                  expectedValue:@(YES)];
    [part ensureDownloading];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) {
        XCTAssertNil(part.error);
        XCTAssertNil(error);
    }];
}

-(void)testFailedDownload {
    BookPart* part = [BookPart new];
    part.url = [NSURL URLWithString:@"BAD_URL/02_Om_denne_udgave.mp3" relativeToURL:baseURL];
    [part deleteCache];
    part.end = 15;
    part.bufferingPoint = part.end;
    
    // we want buffering to fail within 10 seconds
    XCTAssertNil(part.error);
    [self keyValueObservingExpectationForObject:part keyPath:@"error"
                                        handler:^BOOL(id object, NSDictionary* changes) {
                                            return part.error != nil;
                                        }];
    [part ensureDownloading];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) {
        XCTAssertNil(error);
    }];
}

@end
