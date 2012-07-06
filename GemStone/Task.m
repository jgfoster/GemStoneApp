//
//  Task.m
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#define mustOverride() 	[NSException raise:NSInternalInconsistencyException \
format:@"You must override \'%@\' in a subclass", NSStringFromSelector(_cmd)];

#import "Task.h"

#import "AppController.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation Task

- (NSArray *)arguments		{ mustOverride(); return nil; }
- (void)data:(NSData *)data	{ mustOverride(); }
- (void)done				{ mustOverride(); }
- (NSString *)launchPath	{ mustOverride(); return nil; }

- (void)cancelTask;
{
	[task terminate];
	task = nil;
}

- (NSMutableDictionary *)environment;
{
	NSDictionary *myEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *taskEnvironment = [NSMutableDictionary new];
	[taskEnvironment addEntriesFromDictionary:myEnvironment];
	[taskEnvironment setValue:[self currentDirectoryPath] forKey:@"PWD"];
	return taskEnvironment;
}

- (NSString *)currentDirectoryPath;
{
	return [[NSFileManager defaultManager] applicationSupportDirectory];
}

- (void)errorOutput:(NSNotification *)inNotification;
{
	[self progressNotification:inNotification];
}

- (void)notifyDone;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kTaskDone object:self];
}

- (void)progressNotification:(NSNotification *)inNotification;
{
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]) {
		NSString *string = [[NSString alloc] 
							initWithData:data 
							encoding:NSUTF8StringEncoding];
		[[NSNotificationCenter defaultCenter] postNotificationName:kTaskProgress object:string];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadCompletionNotification 
		 object:nil];
		[self done];
	}
}

- (void)standardOutput:(NSNotification *)inNotification;
{
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]) {
		[self data:data];
		[[inNotification object] readInBackgroundAndNotify];
	}
}

- (void)start;
{
	[self verifyNoTask];
	task = [NSTask new];
	[task setCurrentDirectoryPath:[self currentDirectoryPath]];
	[task setLaunchPath:[self launchPath]];
	[task setEnvironment:[self environment]];
	[task setArguments:[self arguments]];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError: [NSPipe pipe]];
	NSFileHandle *taskOut = [[task standardOutput] fileHandleForReading];
	NSFileHandle *taskErr = [[task standardError]  fileHandleForReading];
	
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

- (void)verifyNoTask;
{
	if (task) {
		[NSException raise:NSInternalInconsistencyException
					format:@"Task should not be in progress!"];	
	}
}

@end
