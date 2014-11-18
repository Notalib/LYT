//
//  Library.h
//  player
//
//  Created by Anders Borum on 18/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BridgeController.h"

// Collection of books. This is the outermost controller of playback and books.
@interface Library : NSObject <LytDeviceProtocol>
@property (nonatomic, weak) BridgeController* bridge;

@end
