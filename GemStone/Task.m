//
//  Task.m
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Task.h"
#import "Utilities.h"

@implementation Task

- (NSArray *)arguments {
	return [NSMutableArray new];
}

//	override NSOperation to do our own stuff
- (void)cancel;
{
	[self removeReadCompletionNotifications];
	if (task) {
		NSTask *myTask = task;
		task = nil;
		[myTask terminate];
	}
	[super cancel];
}

//	DatabaseTask has an override for this method
- (NSString *)currentDirectoryPath;
{
	return basePath;
}

- (void)data:(NSData *)data { 
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	[self dataString:string];
}

- (void)dataString:(NSString *)aString;
{
	[self progress:aString];
	[allOutput appendString:aString];
	[standardOutput appendString:aString];
}

- (void)delayFor:(NSTimeInterval)seconds;
{
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

- (void)done;
{
	[self removeReadCompletionNotifications];
    NSLog(@"done %@", NSStringFromClass([self class]));
}

- (void)doneWithError:(int)statusCode;
{
	NSLog(@"done %@ with error (%i)", NSStringFromClass([self class]), statusCode);
	if (statusCode) {
		if (![errorOutput length]) {
			errorOutput = [NSMutableString stringWithFormat:@"Task returned status code %i", statusCode];
		}
		[appController taskError:errorOutput];
	}
	if (![self isCancelled]) {
		[self cancel];
	}
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
	[self progress:aString];
	[allOutput appendString:aString];
	[errorOutput appendString:aString];
}

- (BOOL)isRunning;
{
	return [task isRunning];
}

- (NSString *)launchPath {
	mustOverride();
	return nil;
}

//	override NSOperation to do our work; do not return until done!
- (void)main;
{
	for (NSOperation *priorTask in [self dependencies]) {
		if ([priorTask isCancelled]) {
			return;
		}
	}
	didLaunch = NO;
	@try {
		[self startTask];
		[task waitUntilExit];
		// give a bit of time for output notifications
		for (NSUInteger i = 1; doneCount < 2 && i <= 20; ++i) {
			[self delayFor:0.01 * i];
		}
	}
	@catch (NSException *exception) {
		NSLog(@"Exception in task: %@", exception);
		if (didLaunch) {
			[self cancel];
		}
	}
	@finally {
		// force things to finish without all the output
		while (doneCount < 2) {
			[self mightBeDone];
		}
	}
}

- (void)mightBeDone;
{
	if (++doneCount < 2) return;	//	look for stderr and stdout notifications
	[self removeReadCompletionNotifications];
	if (!task) return;				//	terminated by user, so no need to report error
	for (NSUInteger i = 0; i < 100 && [task isRunning]; ++i) {
		[self delayFor:0.001 * i];
	}
	int status;
	if (didLaunch) {
		status = [task terminationStatus];
	} else {
		status = 1;
	}
	task = nil;
	if (status) {
		[self doneWithError:status];
	} else {
		[self done];
	}
}

- (void)progress:(NSString *)aString;
{
	[appController taskProgress:aString];
}

- (void)removeReadCompletionNotifications;
{
	[notificationCenter
	 removeObserver:self
	 name:NSFileHandleReadCompletionNotification
	 object:nil];
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

- (void)startTask;
{
    NSLog(@"starting %@ in %@", [self className], [NSThread currentThread]);
	task = [NSTask new];
	[task setCurrentDirectoryPath:[self currentDirectoryPath]];
	[task setLaunchPath:[self launchPath]];
	[task setEnvironment:[self environment]];
	[task setArguments:[self arguments]];
	[task setStandardOutput:[NSPipe pipe]];
	[task setStandardError: [NSPipe pipe]];
	[task setStandardInput:[NSPipe pipe]];
	NSFileHandle *taskOut = [[task standardOutput] fileHandleForReading];
	NSFileHandle *taskErr = [[task standardError]  fileHandleForReading];
	
	[notificationCenter
	 addObserver:self 
	 selector:@selector(errorOutput:)
	 name:NSFileHandleReadCompletionNotification
	 object:taskErr];
	[taskErr readInBackgroundAndNotify];
	
	[notificationCenter
	 addObserver:self 
	 selector:@selector(standardOutput:) 
	 name:NSFileHandleReadCompletionNotification
	 object:taskOut];
	[taskOut readInBackgroundAndNotify];
	
	doneCount = 0;
	allOutput = [NSMutableString new];
	errorOutput = [NSMutableString new];
	standardOutput = [NSMutableString new];
	[task launch];
	didLaunch = YES;
}

@end
