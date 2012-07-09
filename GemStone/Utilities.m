//
//  Utilities.m
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#define __Utilities__

#import "Utilities.h"

@implementation Utilities

- (void)setupGlobals;
{
	fileManager = [NSFileManager defaultManager];
	[self setupBasePath];
}

- (void)setupBasePath;
{
	basePath = [@"~/Library/GemStone" stringByExpandingTildeInPath];
	
	if ([fileManager fileExistsAtPath: basePath]) return;
	NSError *error;
	if ([fileManager
		 createDirectoryAtPath:basePath
		 withIntermediateDirectories:NO
		 attributes:nil
		 error:&error]) return;
	AppError(@"Setup Failed: %@", [error description]);
	exit(1);
}

@end
