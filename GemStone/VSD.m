//
//  VSD.m
//  GemStone
//
//  Created by James Foster on 7/18/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Utilities.h"
#import "VSD.h"

@implementation VSD

+ (VSD *)openPath:(NSString *)path usingDatabase:(Database *)database;
{
	VSD *instance = [self forDatabase:database];
	[instance openPath:path];
	return instance;
}

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			path,
			nil];
}

- (void)dataString:(NSString *)aString;
{
	NSLog(@"VSD>>dataString:%@", aString);
}

- (void)errorOutputString:(NSString *)message;
{
	NSLog(@"VSD>>errorOutputString:%@", message);
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/vsd", [database gemstone]];
}

- (void)openPath:(NSString *)aString;
{
	path = aString;
	[self start];
	[notificationCenter
	 removeObserver:self 
	 name:NSFileHandleReadCompletionNotification 
	 object:nil];
	task = nil;
}

@end
