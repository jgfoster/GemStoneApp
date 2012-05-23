//
//  Download.m
//  GemStone
//
//  Created by James Foster on 5/7/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#define mustOverride() 	[NSException raise:NSInternalInconsistencyException \
									format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];

#import "Download.h"
#import "AppController.h"
#import "NSFileManager+DirectoryLocations.h"

@implementation Download

- (NSArray *)arguments		{ mustOverride(); return nil; }
- (void)data:(NSData *)data	{ mustOverride(); }
- (void)done				{ mustOverride(); }
- (NSString *)path			{ mustOverride(); return nil; }

- (void)cancelTask;
{
	[task terminate];
	task = nil;
}

- (void)errorOutput:(NSNotification *)inNotification;
{
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]) {
		NSString *string = [[NSString alloc] 
							initWithData:data 
							encoding:NSUTF8StringEncoding];
		[[NSNotificationCenter defaultCenter] postNotificationName:kDownloadProgress object:string];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadCompletionNotification 
		 object:nil];
		[self done];
	}
}

- (void)notifyDone;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kDownloadDone object:self];
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
	[task setCurrentDirectoryPath:[[NSFileManager defaultManager] applicationSupportDirectory]];
	[task setLaunchPath:[self path]];
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
