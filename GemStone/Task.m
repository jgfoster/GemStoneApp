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

@implementation Task

- (NSArray *)arguments		{ mustOverride(); return nil; }
- (void)done				{ mustOverride(); }
- (NSString *)launchPath	{ mustOverride(); return nil; }

- (void)cancelTask;
{
	[[NSNotificationCenter defaultCenter] 
	 removeObserver:self 
	 name:NSFileHandleReadCompletionNotification 
	 object:nil];
	[task terminate];
	task = nil;
}

- (NSString *)currentDirectoryPath;
{
	return [[NSApp delegate] basePath];
}

- (void)data:(NSData *)data { 
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	[self dataString:string];
}

- (void)dataString:(NSString *)aString { 
	[standardOutput appendString:aString];
	[self progress:aString];
}

- (void)doneWithError:(int)statusCode;
{
	if (![errorOutput length]) {
		errorOutput = [NSString stringWithFormat:@"Task returned status code %i", statusCode];
	}
	NSDictionary *userInfo = [NSDictionary
							  dictionaryWithObject:errorOutput
							  forKey:@"string"];
	NSNotification *outNotification = [NSNotification
									   notificationWithName:kTaskError
									   object:self
									   userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:outNotification];
	[self notifyDone];
}

- (NSMutableDictionary *)environment;
{
	NSDictionary *myEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *taskEnvironment = [NSMutableDictionary new];
	[taskEnvironment addEntriesFromDictionary:myEnvironment];
	[taskEnvironment setValue:[self currentDirectoryPath] forKey:@"PWD"];
	return taskEnvironment;
}

- (void)error:(NSString *)aString;
{
}

- (void)errorOutput:(NSNotification *)inNotification;
{
	if (!task) return;
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]) {
		NSString *string = [[NSString alloc] 
							initWithData:data 
							encoding:NSUTF8StringEncoding];
		[errorOutput appendString:string];
		[self error: string];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[self mightBeDone];
	}
}

- (void)mightBeDone;
{
	if (++doneCount < 2) return;
	[[NSNotificationCenter defaultCenter] 
	 removeObserver:self 
	 name:NSFileHandleReadCompletionNotification 
	 object:nil];
	int status = [task terminationStatus];
	if (status) {
		[self doneWithError:status];
	} else {
		[self done];
	}
}

- (void)notifyDone;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kTaskDone object:self];
}

- (void)progress:(NSString *)aString;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kTaskProgress object:aString];
}

- (void)standardOutput:(NSNotification *)inNotification;
{
	if (!task) return;
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]) {
		[self data:data];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[self mightBeDone];
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
	doneCount = 0;
	errorOutput = [NSMutableString new];
	standardOutput = [NSMutableString new];
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
