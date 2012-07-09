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
#import "Utilities.h"

@implementation Task

- (NSArray *)arguments		{ mustOverride(); return nil; }
- (NSString *)launchPath	{ mustOverride(); return nil; }

- (void)cancelTask;
{
	[[NSNotificationCenter defaultCenter] 
	 removeObserver:self 
	 name:NSFileHandleReadCompletionNotification 
	 object:nil];
	NSTask *myTask = task;
	task = nil;
	[myTask terminate];
}

- (NSString *)currentDirectoryPath;
{
	return basePath;
}

- (void)data:(NSData *)data { 
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	[self dataString:string];
}

- (void)dataString:(NSString *)aString { 
	[standardOutput appendString:aString];
}

- (void)done;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kTaskDone object:self];
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
}

- (NSMutableDictionary *)environment;
{
	NSDictionary *myEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *taskEnvironment = [NSMutableDictionary new];
	[taskEnvironment addEntriesFromDictionary:myEnvironment];
	[taskEnvironment setValue:[self currentDirectoryPath] forKey:@"PWD"];
	return taskEnvironment;
}

- (void)errorOutput:(NSNotification *)inNotification;
{
	if (!task) return;
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]) {
		NSString *string = [[NSString alloc] 
							initWithData:data 
							encoding:NSUTF8StringEncoding];
		[self errorOutputString: string];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[self mightBeDone];
	}
}

- (void)errorOutputString:(NSString *)aString;
{
	[errorOutput appendString:aString];
}

- (void)mightBeDone;
{
	if (++doneCount < 2) return;	//	look for stderr and stdout notifications
	[[NSNotificationCenter defaultCenter] 
	 removeObserver:self 
	 name:NSFileHandleReadCompletionNotification 
	 object:nil];
	if (!task) return;				//	terminated by user, so no need to report error
	int status = [task terminationStatus];
	task = nil;
	if (status) {
		[self doneWithError:status];
	} else {
		[self done];
	}
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
