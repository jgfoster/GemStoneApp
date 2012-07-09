//
//  ImportZippedVersion.m
//  GemStone
//
//  Created by James Foster on 5/8/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "ImportZippedVersion.h"
#import "Utilities.h"

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
			basePath,
			nil];
}

- (void)done;
{
	NSRange range;
	range = [zipFilePath rangeOfString:basePath];
	if (0 == range.location) {
		[fileManager removeItemAtPath:zipFilePath error:nil];
	}
	[super done];
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
