/*
 *  debug.h
 *  Tegneri
 *
 *  Created by Anders Borum on 23/04/10.
 *  Copyright 2010 Algoritmer En Gros. All rights reserved.
 *
 */

#include <assert.h>

#define AssertMainThread() assert([NSThread isMainThread])

#ifndef _BORUM_DEBUG_H_
#define _BORUM_DEBUG_H_

#ifndef  NDEBUG

# define DBGLog(fmt, args...)      NSLog(fmt, ## args)

# define DBGSaveNSImage(nsimage, filename) ({                                             \
                            NSAutoreleasePool* _save_pool_ = [NSAutoreleasePool new];     \
                            NSData* _png_data_ = UIImagePNGRepresentation(nsimage);       \
                            [_png_data_ writeToFile:filename atomically:FALSE];           \
                            [_save_pool_ release];                                        \
                        })
# define DBGSaveCGImage(cgimage, filename) ({                                             \
                            NSAutoreleasePool* _save_pool_ = [NSAutoreleasePool new];     \
                            UIImage* _nsimage_ = [UIImage imageWithCGImage:cgimage];      \
                            NSData* _png_data_ = UIImagePNGRepresentation(_nsimage_);     \
                            [_png_data_ writeToFile:filename atomically:FALSE];           \
                            [_save_pool_ release];                                        \
})

#define AssertArrayKind(elements, Type) ({ for(NSObject* element in elements) {             \
                                             assert([element isKindOfClass:[Type class]]);  \
                                        }})

// describeViewVisibility(view) returns text describing if view is hidden and why
// looking at hidden property, alpha, whether is in current view hierarchy,
// whether frame is outside parent frame or empty and later we could check if
// occluded by other views.
@class UIView;
NSString* _describeViewVisibility(UIView* uiView);
#define describeViewVisibility(uiView) _describeViewVisibility(uiView)

#else

# define DBGLog(fmt, args...)
# define DBGSaveNSImage(nsimage, filename)
# define DBGSaveCGImage

#define AssertArrayKind(elements, Type)

#define describeViewVisibility(uiView) nil

#endif

#define DB0Log(fmt, args...)
#define DBGLogTransform(matrix) DBGLog(@"%4f %4f | %4f\n%4f %4f | %4f", matrix.a, matrix.b, matrix.tx, matrix.c, matrix.d, matrix.ty)

#define DBGLogRect(rect) DBGLog(@"%dx%d w=%d h=%d", (int)rect.origin.x, (int)rect.origin.y, (int)rect.size.width, (int)rect.size.height)


#endif//_BORUM_DEBUG_H_
