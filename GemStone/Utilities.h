//
//  Utilities.h
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppController.h"

#define AppError(...) 	[NSException raise:NSInternalInconsistencyException \
									format:[NSString stringWithFormat:__VA_ARGS__]]

#ifdef __Utilities__
			AppController			*appController = nil;
			NSFileManager			*fileManager = nil;
			NSString				*basePath = nil;
			NSNotificationCenter	*notificationCenter = nil;
#else
	extern	AppController			*appController;
	extern	NSFileManager			*fileManager;
	extern	NSString				*basePath;
	extern  NSNotificationCenter	*notificationCenter;
#endif

@interface Utilities : NSObject

- (void)setupGlobals:(AppController *)myApp;

@end
