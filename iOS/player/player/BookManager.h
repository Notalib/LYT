//
//  Library.h
//  player
//
//  Created by Anders Borum on 18/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BridgeController.h"

// identifier for location nofication action that starts playback without makeing
// app enter foreground
#define PlayActionIdentifier @"play"

// Collection of books. This is the outermost controller of playback and books.
@interface BookManager : NSObject <LytDeviceProtocol>
@property (nonatomic, weak) BridgeController* bridge;

// called when we are ready to process requests 
-(void)ready;

// notifications can be used to start playing some book
+(void)handleLocalNotification:(UILocalNotification*)notification;

@end
