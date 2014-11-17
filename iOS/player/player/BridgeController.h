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
-(void)clearBookCache:(NSString*)bookId;

@end

@interface BridgeController : NSObject <UIWebViewDelegate>
@property (nonatomic, weak) id<LytDeviceProtocol> delegate;

@end
