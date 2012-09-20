//
//  UnzipVersion.m
//  GemStone
//
//  Created by James Foster on 9/19/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "UnzipVersion.h"
#import "Utilities.h"

@implementation UnzipVersion

@synthesize zipFilePath;

- (NSArray *)arguments;
{
	if (!zipFilePath) AppError(@"Zip file path must be provided!");	
	return [NSArray arrayWithObjects:
			zipFilePath, 
			@"-d",
			basePath,
			nil];
}

- (void)cancel;
{
	[super cancel];
	if (!directoryContents) return;
	[notificationCenter postNotificationName:kTaskProgress 
									  object:@"\n\nCancel request received.\nDeleting unzipped items . . .\n"];
	NSError *error = nil;
	NSArray *currentList = [fileManager contentsOfDirectoryAtPath:basePath error:&error];
	if (!currentList) AppError(@"Unable to obtain contents of directory at %@", basePath);
	for (id current in currentList) {
		Boolean	flag = NO;
		for (id prior in directoryContents) {
			flag = flag || [current isEqualToString:prior];
		}
		if (!flag) {
			NSString *path = [[basePath stringByAppendingString:@"/"] stringByAppendingString:current];
			[Version removeVersionAtPath:path];
		}
	}
	if ([zipFilePath hasPrefix:basePath]) {
		[fileManager removeItemAtPath:zipFilePath error:nil];
	}
}

- (void)dataString:(NSString *)aString;
{
	[self progress:aString];
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

- (void)main;
{
	NSError *error = nil;
	directoryContents = [fileManager contentsOfDirectoryAtPath:basePath error:&error];
	if (!directoryContents) AppError(@"Unable to obtain contents of %@", basePath);
	[super main];
}

@end
