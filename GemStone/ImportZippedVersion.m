//
//  ImportZippedVersion.m
//  GemStone
//
//  Created by James Foster on 5/8/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "ImportZippedVersion.h"

#import "AppController.h"

@implementation ImportZippedVersion

@synthesize zipFilePath;

- (NSArray *)arguments;
{
	if (!zipFilePath) {
		[NSException raise:NSInternalInconsistencyException
					format:@"Zip file path must be provided!"];	
	}
	return [NSArray arrayWithObjects:
			zipFilePath, 
			@"-d",
			[[NSApp delegate] basePath],
			nil];
}

- (void)done;
{
	NSRange range;
	range = [zipFilePath rangeOfString:[[NSApp delegate] basePath]];
	if (0 == range.location) {
		[[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
	}
	[self notifyDone];
}

- (NSString *)launchPath;
{
	return @"/usr/bin/unzip";
}

- (void)dataString:(NSString *)aString;
{
	[self progress:aString];
}

@end
