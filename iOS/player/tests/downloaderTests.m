//
//  downloaderTests.m
//  player
//
//  Created by Anders Borum on 24/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Downloader.h"


// Test files for downloading described at:
//    http://www.thinkbroadband.com/download.html
@interface downloaderTests : XCTestCase {
    // MD5 for 50MB.zip: 2699c63cb6699b2272f78989b09e88b1 size: 52428800 bytes
    NSURL* url50MB;
}

@end

@implementation downloaderTests

// Make sure we can instantiate and that instances are shared when URL and start time matches
-(void)testInstantiation {
    Downloader* a = [Downloader downloadURL:url50MB];
    XCTAssertNotNil(a, @"Expected downloader for %@", url50MB);
    
    Downloader* b = [Downloader downloadURL:url50MB start:0 end:1000];
    XCTAssertTrue(a == b, @"Expected identical references");

    Downloader* c = [Downloader downloadURL:url50MB start:1000 end:2000];
    XCTAssertTrue(a != c, @"Expected different references");
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"progressBytes"]) {
        Downloader* downloader = object;
        NSLog(@"Downloaded %ld/%ld of %@", (long)downloader.progressBytes,
              (long)(downloader.end - downloader.start), downloader);
    }
}

// Try to download entire file, making sure it matches MD5 we have
-(void)testFullDownload {
    // we use KVO notifications to determine when download has completed
    Downloader* a = [Downloader downloadURL:url50MB];
    [a addObserver:self forKeyPath:@"progressBytes" options:0 context:NULL];
    
    [self keyValueObservingExpectationForObject:a keyPath:@"progressBytes"
                                            expectedValue:@(52428800)];
    XCTestExpectation* noError = [self keyValueObservingExpectationForObject:a keyPath:@"error"
                                                                     handler:^(id observedObject, NSDictionary *change) {
                                                                         XCTAssertNil(a.error);
                                                                         return YES;
    }];
    
    [a download];
    
    [self waitForExpectationsWithTimeout:100 handler:^(NSError* error) {
        XCTAssertNil(error);
    }];
}

- (void)setUp {
    [super setUp];
   
    url50MB = [NSURL URLWithString:@"http://ipv4.download.thinkbroadband.com/50MB.zip"];
}

@end
