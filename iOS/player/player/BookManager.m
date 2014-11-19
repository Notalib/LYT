//
//  Library.m
//  player
//
//  Created by Anders Borum on 18/11/14.
//  Copyright (c) 2014 NOTA. All rights reserved.
//

#import "BookManager.h"
#import "Downloader.h"
#import "debug.h"

@interface BookManager () {
    NSMutableDictionary* booksById;
    NSMutableSet* booksDownloading; // books we are downloading in their entirety
    NSString* currentBookId; // the playing book is always current, but the current book might not be playing
}

@end

@implementation BookManager
@synthesize bridge;

-(instancetype)init {
    self = [super init];
    if(self) {
        booksById = [NSMutableDictionary new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunchingNotification:)
                                                     name:UIApplicationDidFinishLaunchingNotification object:nil];
    }
    return self;
}

static NSString* playBookRequest = nil;
static BookManager* anyManager = nil;

-(void)ready {
    anyManager = self;
    
    [Downloader processBackgroundSessionCompletionHandler];
    if(playBookRequest.length > 0) {
        [self play:playBookRequest offset:-1];
        playBookRequest = nil;
    }
}


-(void)didFinishLaunchingNotification:(NSNotification*)notification {
    UILocalNotification* localNotification = [notification.userInfo objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    
    if(localNotification) {
        [BookManager handleLocalNotification:localNotification];
    }
}

+(void)handleLocalNotification:(UILocalNotification*)notification {
    NSString* bookId = [notification.userInfo objectForKey:@"bookId"];
    if(bookId.length > 0) {
        // we start playing book if we have instance of PlayerManager, otherwise we queue
        // for launch
        if(anyManager) {
            [anyManager play:bookId offset:-1];
        } else {
            playBookRequest = bookId;
        }
    }
}

-(void)requestNotificationsPermission {
    UIApplication* app = [UIApplication sharedApplication];
    if([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge |
                                       UIUserNotificationTypeSound;
        UIMutableUserNotificationAction* play = [UIMutableUserNotificationAction new];
        play.identifier = PlayActionIdentifier;
        play.title = NSLocalizedString(@"Listen", nil);
        play.activationMode = UIUserNotificationActivationModeBackground;
        play.destructive = NO;
        play.authenticationRequired = NO;
        
        UIMutableUserNotificationCategory* playCategory = [UIMutableUserNotificationCategory new];
        playCategory.identifier = PlayActionIdentifier;
        [playCategory setActions:@[play] forContext:UIUserNotificationActionContextDefault];
        [playCategory setActions:@[play] forContext:UIUserNotificationActionContextMinimal];
                                                                                                                                                                                                         
        NSSet* categories = [NSSet setWithObject:playCategory];
        UIUserNotificationSettings* settings =  [UIUserNotificationSettings settingsForTypes:types categories:categories];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

-(void)setBridge:(BridgeController *)theBridge {
    if(theBridge == bridge) return;
    
    bridge.delegate = nil;
    bridge = theBridge;
    bridge.delegate = self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setBridge:nil];
}

-(void)downloadCompletedBook:(Book*)book {
    // ignore invalid books, to avoid crashes on bad data
    if(book.identifier.length == 0) return;
    
    [bridge completedDownloadBook:book.identifier timestamp:[NSDate date]];
    
    // perform notification when app is in the background
    UIApplication* app = [UIApplication sharedApplication];
    if(app.applicationState == UIApplicationStateBackground) {
        NSString* format = NSLocalizedString(@"%@ er hentet ned på %@.", nil);
        NSString* message = [NSString stringWithFormat:format, book.title, [UIDevice currentDevice].name];
        
        UILocalNotification* notification = [UILocalNotification new];
        notification.alertBody = message;
        notification.userInfo = @{@"bookId": book.identifier};
        
        // on iOS 8 we use interactive notification to allow playback,
        // before iOS 8 we use regular action that enters app
        if([notification respondsToSelector:@selector(setCategory:)]) {
            notification.category = PlayActionIdentifier;
            notification.hasAction = NO;
        } else {
            notification.alertAction = NSLocalizedString(@"listen", nil);
        }
        
        [app presentLocalNotificationNow:notification];
    }
}

#pragma mark LytDeviceProtocol

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                       change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"error"]) {
        Book* book = object;
        NSError* error = book.error;
        if(error) {
            NSString* message = error.localizedDescription;
            if([error.domain isEqualToString:NSURLErrorDomain]) {
                if(error.code == kCFURLErrorUserAuthenticationRequired) {
                    message = NSLocalizedString(@"Authentication required", nil);
                }
            }
            
            [bridge downloadBook: book.identifier failed:message];
        }
    } else if([keyPath isEqualToString:@"isPlaying"]) {
        Book* book = object;
        
        // book must have ended and be very close to end
        if(!book.isPlaying && book.position >= book.duration - 1.0) {
            [bridge endBook: book.identifier];
        }
    }
}

-(void)sendBookUpdate {
    Book* book = self.currentBook;
    if(book) {
        [bridge updateBook:book.identifier offset:book.position];
    }
    
    // we schedule update while book is playing
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendBookUpdate) object:nil];
    if(book.isPlaying) {
        [self performSelector:@selector(sendBookUpdate) withObject:nil afterDelay:0.1];
    }
}

-(void)sendDownloadUpdates {
    for (Book* book in booksDownloading.allObjects) {
        if(book.downloaded) {
            [self downloadCompletedBook: book];
        } else {
            CGFloat progress = book.ensuredBufferingPoint / book.duration;
            CGFloat percent = 100.0 * progress;
            [bridge downloadBook:book.identifier progress:percent];
        }
        
        // stop following book not either playing or downloading
        if(!book.downloading && !book.isPlaying) {
            [booksDownloading removeObject:book];
        }
    }
    
    // schedule on one second if there is anything still downloading
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendDownloadUpdates) object:nil];
    if(booksDownloading.count > 0) {
        [self performSelector:@selector(sendDownloadUpdates) withObject:nil afterDelay:1];
    }
}

-(NSArray*)booksState {
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:booksById.count];
    for (Book* book in booksById.allValues) {
        NSDictionary* info = @{@"id": book.identifier, @"offset": @(book.position),
                               @"downloaded": @(book.downloaded)};
        [array addObject:info];
    }
    return array;
}

-(Book*)currentBook {
    if(currentBookId == nil) return nil;
    return [booksById objectForKey:currentBookId];
}

-(void)setBook:(id)bookData {
    NSURL* baseURL = [NSURL URLWithString:@"http://m.e17.dk/DodpFiles/20005/37027/"];
    NSDictionary* dict = nil;
    if([bookData isKindOfClass:[NSDictionary class]]) {
        dict = (NSDictionary*)bookData;
    } else if([bookData isKindOfClass:[NSString class]]) {
        // book-data can be double-wrapped as JSON
        NSString* string = (NSString*)bookData;
        NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
        dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if(![dict isKindOfClass:[NSDictionary class]]) dict = nil;
    }
    
    if(!dict) return;
    
    Book* book = [Book bookFromDictionary:dict baseURL:baseURL];
    [book joinParts];
    //[book deleteCache];
    book.bufferLookahead = 20;
    
    NSString* key = book.identifier;
    if(key) {
        [self clearBook:key];
        [booksById setObject:book forKey:key];
        
        [book addObserver:self forKeyPath:@"isPlaying" options:0 context:NULL];
        [book addObserver:self forKeyPath:@"error" options:0 context:NULL];
    }
}

-(void)clearBook:(NSString*)bookId {
    if(bookId) {
        Book* book = [booksById objectForKey:bookId];
        [book removeObserver:self forKeyPath:@"isPlaying"];
        [book removeObserver:self forKeyPath:@"error"];
        
        [book stop];
        [book deleteCache];
        [booksById removeObjectForKey:bookId];
    }
}

-(void)clearAllBooks {
    for (Book* book in booksById.allValues) {
        [self clearBook:book.identifier];
    }
}

-(void)play:(NSString*)bookId offset:(NSTimeInterval)offset {
    Book* oldBook = self.currentBook;
    if(![oldBook.identifier isEqualToString:bookId]) {
        [oldBook stop];
    }
    
    Book* book = [booksById objectForKey:bookId];
    currentBookId = book.identifier; // if bookId was not valid, book.identifier will be nil, which is wanted behaviour
    
    // negative offsets mean current position
    if(offset < 0.0) offset = book.position;
    book.position = offset;

    [book play];
    [self sendBookUpdate];
    [self sendDownloadUpdates];
}

-(void)stop {
    Book* oldBook = self.currentBook;
    [oldBook stop];
}

-(void)cacheBook:(NSString*)bookId {
    // we ask for permission to send notifications when user asks to cache, since we notify when done
    [self requestNotificationsPermission];
    
    Book* book = [booksById objectForKey:bookId];
    book.bufferLookahead = 999999;
    
    if(!booksDownloading) {
        booksDownloading = [NSMutableSet new];
    }
    [booksDownloading addObject:book];
    [self sendDownloadUpdates];
}

-(void)clearBookCache:(NSString*)bookId {
    Book* book = [booksById objectForKey:bookId];
    if(book) {
        [booksDownloading removeObject:book];
        [book deleteCache];
    }
}

#pragma mark -

@end
