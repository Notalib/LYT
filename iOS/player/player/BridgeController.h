//
//  BridgeController.h
//  player
//
//  Created by Anders Borum on 17/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Book.h"

@protocol LytDeviceProtocol <NSObject>

-(void)setBook:(id)bookData;
-(void)clearBook:(NSString*)bookId;
-(void)play:(NSString*)bookId offset:(NSTimeInterval)offset;
-(void)stop;

-(void)cacheBook:(NSString*)bookId;
-(void)cancelBookCaching:(NSString*)bookId;
-(void)clearBookCache:(NSString*)bookId;

// consumer should report back array of dictionary elements with book state on the form:
// [ { 'id': <book id>, 'offset': <offset>, 'downloaded': <downloaded> },
//   ...
// ]
-(NSArray*)booksState;

@end

@interface BridgeController : NSObject <UIWebViewDelegate>
@property (nonatomic, weak) id<LytDeviceProtocol> delegate;
@property (nonatomic, weak) UIWebView* webView;

// makes controller update list of book from its delegate and write it to web layer
-(void)refreshBooks;

#pragma mark Events
-(void)updateBook:(NSString*)bookId offset:(NSTimeInterval)offset;
-(void)endBook:(NSString*)bookId;
-(void)stopBook:(NSString*)bookId;

-(void)downloadBook:(NSString*)bookId progress:(CGFloat)percent;
-(void)downloadBook:(NSString*)bookId failed:(NSString*)reason;
-(void)completedDownloadBook:(NSString*)bookId timestamp:(NSDate*)timestamp;

-(void)connectivityChangedOnline:(BOOL)online;
#pragma mark -

@end
