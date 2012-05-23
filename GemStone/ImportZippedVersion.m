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

- (void)standardOutput:(NSNotification *)inNotification {
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
		[[inNotification object] readInBackgroundAndNotify];
		NSDictionary *userInfo = [NSDictionary
								  dictionaryWithObject:string
								  forKey:@"string"];
		NSNotification *outNotification = [NSNotification
										   notificationWithName:kImportProgress
										   object:self
										   userInfo:userInfo];
		[[NSNotificationCenter defaultCenter] postNotification:outNotification];
	}
}

- (void)start;
{
	if (!zipFilePath) {
		[NSException raise:NSInternalInconsistencyException
					format:@"Zip file path must be provided!"];	
	}
	if (task) {
		[NSException raise:NSInternalInconsistencyException
					format:@"Task should not be in progress!"];	
	}
	task = [NSTask new];
	[task setCurrentDirectoryPath:[[NSFileManager defaultManager] applicationSupportDirectory]];
	NSArray	*arguments = [NSArray arrayWithObjects:
						  zipFilePath, 
						  @"-d",
						  [[NSFileManager defaultManager] applicationSupportDirectory],
						  nil];
	[task setLaunchPath:@"/usr/bin/unzip"];
	[task setArguments:arguments];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError: [NSPipe pipe]];
	NSFileHandle *taskOut = [[task standardOutput] fileHandleForReading];
	NSFileHandle *taskErr = [[task standardError] fileHandleForReading];
	
	[[NSNotificationCenter defaultCenter] 
	 addObserver:self 
	 selector:@selector(errorOutput:)
	 name:NSFileHandleReadCompletionNotification
	 object:taskErr];
	[taskErr readInBackgroundAndNotify];
	
	[[NSNotificationCenter defaultCenter] 
	 addObserver:self 
	 selector:@selector(standardOutput:) 
	 name:NSFileHandleReadCompletionNotification
	 object:taskOut];
	[taskOut readInBackgroundAndNotify];
	[task launch];	
}

@end
