//
//  ImportZippedVersion.m
//  GemStone
//
//  Created by James Foster on 5/8/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "ImportZippedVersion.h"

#import "AppController.h"
#import "NSFileManager+DirectoryLocations.h"

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
			[[NSFileManager defaultManager] applicationSupportDirectory],
			nil];
}

- (NSString *)currentDirectoryPath;
{
	return [[NSFileManager defaultManager] applicationSupportDirectory];
}

- (void)done;
{
	
}

- (void)errorOutput:(NSNotification *)inNotification;
{
	[[NSNotificationCenter defaultCenter] 
	 removeObserver:self 
	 name:NSFileHandleReadCompletionNotification 
	 object:nil];	//	this removes both stdout and stderr
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
		[self importTaskErrored:string];
	} else {
		[self importTaskFinished];
	}
}

- (void)importTaskErrored:(NSString *)message;
{
	[task terminate];
	NSDictionary *userInfo = [NSDictionary
							  dictionaryWithObject:message
							  forKey:@"string"];
	NSNotification *outNotification = [NSNotification
									   notificationWithName:kImportError 
									   object:self
									   userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:outNotification];
}

- (void)importTaskFinished;
{
	NSRange range;
	range = [zipFilePath rangeOfString:[[NSFileManager defaultManager] applicationSupportDirectory]];
	if (0 == range.location) {
		[[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kImportDone object:self];
}

- (NSString *)launchPath;
{
	return @"/usr/bin/unzip";
}

- (void)standardOutput:(NSNotification *)inNotification;
{
	[self progressNotification:inNotification];
}

@end
