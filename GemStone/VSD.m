//
//  VSD.m
//  GemStone
//
//  Created by James Foster on 7/18/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
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

- (NSString *)binName;
{
	return @"%vsd";
}

- (void)dataString:(NSString *)aString;
{
	NSLog(@"VSD>>dataString:%@", aString);
}

- (void)errorOutputString:(NSString *)message;
{
	NSLog(@"VSD>>errorOutputString:%@", message);
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
