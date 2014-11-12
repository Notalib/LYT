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

@interface playerTests : XCTestCase

@end

@implementation playerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testReadBook {
    // TODO: Right now we need to edit baseURL by hand, but to make repeatable tests we
    // need some way to obtain the last number.
    NSURL* baseURL = [NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20008/37027/"];
    
    NSString* path = [[NSBundle mainBundle] pathForResource:@"bunker137.json" ofType:nil];
    NSData* data = [NSData dataWithContentsOfFile:path];
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
    XCTAssertNotNil(json);
    
    Book* book = [Book bookFromDictionaries:json baseURL:baseURL];
    NSLog(@"book = %@", book.parts);
    XCTAssertNotNil(book);
    XCTAssertTrue(book.parts.count >= 1);
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
