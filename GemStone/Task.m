//
//  Task.m
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Task.h"
#import "Utilities.h"

@interface Task ()

@property	int		doneCount;
@property	BOOL	didLaunch;

@end

@implementation Task

- (NSArray *)arguments {
	return [NSMutableArray new];
}

//	override NSOperation to do our own stuff
- (void)cancel {
	[self removeReadCompletionNotifications];
	if (self.task) {
		NSTask *myTask = self.task;
		self.task = nil;
		[myTask terminate];
	}
	[super cancel];
}

//	DatabaseTask has an override for this method
- (NSString *)currentDirectoryPath {
	return basePath;
}

- (void)data:(NSData *)data { 
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	[self dataString:string];
}

- (void)dataString:(NSString *)aString {
	[self progress:aString];
	[self.allOutput appendString:aString];
	[self.standardOutput appendString:aString];
}

- (void)delayFor:(NSTimeInterval)seconds {
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

- (void)done {
	[self removeReadCompletionNotifications];
//	NSLog(@"done %@", NSStringFromClass([self class]));
}

- (void)doneWithError:(int)statusCode;
{
//	NSLog(@"done %@ with error (%i)", NSStringFromClass([self class]), statusCode);
	if (statusCode) {
		if (![self.errorOutput length]) {
			self.errorOutput = [NSMutableString stringWithFormat:@"Task returned status code %i", statusCode];
		}
		[appController taskError:self.errorOutput];
	}
	if (![self isCancelled]) {
		[self cancel];
	}
}

- (NSMutableDictionary *)environment {
	NSDictionary *myEnvironment = [[NSProcessInfo processInfo] environment];
	NSMutableDictionary *taskEnvironment = [NSMutableDictionary new];
	[taskEnvironment addEntriesFromDictionary:myEnvironment];
	[taskEnvironment setValue:[self currentDirectoryPath] forKey:@"PWD"];
	return taskEnvironment;
}

- (void)errorOutput:(NSNotification *)inNotification {
	if (!self.task) return;
	if ([self isCancelled]) return;
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

- (void)errorOutputString:(NSString *)aString {
	[self progress:aString];
	[self.allOutput appendString:aString];
	[self.errorOutput appendString:aString];
}

- (BOOL)isRunning {
	return [self.task isRunning];
}

- (NSString *)launchPath {
	mustOverride();
	return nil;
}

//	override NSOperation to do our work; do not return until done!
- (void)main {
	for (NSOperation *priorTask in [self dependencies]) {
		if ([priorTask isCancelled]) {
			return;
		}
	}
	self.didLaunch = NO;
	@try {
		[self startTask];
		[self.task waitUntilExit];
		// give a bit of time for output notifications
		for (NSUInteger i = 1; self.doneCount < 2 && i <= 20; ++i) {
			[self delayFor:0.01 * i];
		}
	}
	@catch (NSException *exception) {
		NSLog(@"Exception in task: %@", exception);
		if (self.didLaunch) {
			[self cancel];
		}
	}
	@finally {
		// force things to finish without all the output
		while (self.doneCount < 2) {
			[self mightBeDone];
		}
	}
}

- (void)mightBeDone {
	if (++_doneCount < 2) return;	//	look for stderr and stdout notifications
	[self removeReadCompletionNotifications];
	if (!self.task) return;				//	terminated by user, so no need to report error
	for (NSUInteger i = 0; i < 100 && [self.task isRunning]; ++i) {
		[self delayFor:0.001 * i];
	}
	int status;
	if (self.didLaunch) {
		status = [self.task terminationStatus];
	} else {
		status = 1;
	}
	self.task = nil;
	if (status) {
		[self doneWithError:status];
	} else {
		[self done];
	}
}

- (void)progress:(NSString *)aString {
	[appController taskProgress:aString];
}

- (void)removeReadCompletionNotifications {
	[notificationCenter
	 removeObserver:self
	 name:NSFileHandleReadCompletionNotification
	 object:nil];
}

- (void)standardOutput:(NSNotification *)inNotification {
	if (!self.task) return;
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
//	NSLog(@"starting %@ in %@", [self className], [NSThread currentThread]);
	self.task = [NSTask new];
	[self.task setCurrentDirectoryPath:[self currentDirectoryPath]];
	[self.task setLaunchPath:[self launchPath]];
	[self.task setEnvironment:[self environment]];
	[self.task setArguments:[self arguments]];
	[self.task setStandardOutput:[NSPipe pipe]];
	[self.task setStandardError: [NSPipe pipe]];
	[self.task setStandardInput:[NSPipe pipe]];
	NSFileHandle *taskOut = [[self.task standardOutput] fileHandleForReading];
	NSFileHandle *taskErr = [[self.task standardError]  fileHandleForReading];
	
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
	
	self.doneCount = 0;
	self.allOutput = [NSMutableString new];
	self.errorOutput = [NSMutableString new];
	self.standardOutput = [NSMutableString new];
	[self.task launch];
	self.didLaunch = YES;
}

@end
