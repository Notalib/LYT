//
//  downloaderTests.m
//  player
//
//  Created by Anders Borum on 24/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonDigest.h>
#import "Downloader.h"

// Test files for downloading described at:
//    http://www.thinkbroadband.com/download.html
@interface downloaderTests : XCTestCase {
    // MD5 for 50MB.zip: 2699c63cb6699b2272f78989b09e88b1 size: 52428800 bytes
    NSURL* url50MB;
    
    // MD5 for 50MB.zip: b3215c06647bc550406a9c8ccc378756 size:  5242880 bytes
    NSURL* url5MB;
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

-(NSString*)md5ForData:(NSData*)data {
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(data.bytes, (CC_LONG)data.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

// Try to download entire file, making sure it matches MD5 we have
-(void)testFullDownloadURL:(NSURL*)url length:(NSUInteger)length md5:(NSString*)md5 {
    // we use KVO notifications to determine when download has completed
    Downloader* a = [Downloader downloadURL:url];
    [a deleteCache]; // deleting cache has the side-effect of setting downloader to not want any data,
    a = [Downloader downloadURL:url];     // which is why we request one again
    [a addObserver:self forKeyPath:@"progressBytes" options:0 context:NULL];
    
    [self keyValueObservingExpectationForObject:a keyPath:@"progressBytes"
                                            expectedValue:@(length)];
    [self keyValueObservingExpectationForObject:a keyPath:@"error"
                                        handler:^(id observedObject, NSDictionary *change) {
                                            XCTAssertNil(a.error);
                                            return YES;
    }];
    
    [a download];
    
    [self waitForExpectationsWithTimeout:100 handler:^(NSError* error) {
        XCTAssertNil(error);
        
        NSData* data = [NSData dataWithContentsOfFile:a.cachePath];
        NSString* actualMD5 = [self md5ForData:data];
        XCTAssertEqualObjects(actualMD5, md5);
        
    }];
    
    [a removeObserver:self forKeyPath:@"progressBytes"];
}

-(void)testFullDownloads {
    [self testFullDownloadURL:url50MB length:52428800 md5:@"2699c63cb6699b2272f78989b09e88b1"];
    [self testFullDownloadURL:url5MB length:5242880 md5:@"b3215c06647bc550406a9c8ccc378756"];
}

- (void)setUp {
    [super setUp];
   
    url5MB = [NSURL URLWithString:@"http://ipv4.download.thinkbroadband.com/5MB.zip"];
    url50MB = [NSURL URLWithString:@"http://ipv4.download.thinkbroadband.com/50MB.zip"];
}

@end
