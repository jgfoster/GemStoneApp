//
//  Utilities.h
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define AppError(...) 	[NSException raise:NSInternalInconsistencyException \
									format:[NSString stringWithFormat:__VA_ARGS__]]

#ifdef __Utilities__
			NSFileManager			*fileManager = nil;
			NSString				*basePath = nil;
			NSNotificationCenter	*notificationCenter = nil;
#else
	extern	NSFileManager			*fileManager;
	extern	NSString				*basePath;
	extern  NSNotificationCenter	*notificationCenter;
#endif

@interface Utilities : NSObject

- (void)setupGlobals;

@end
