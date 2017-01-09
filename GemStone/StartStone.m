//
//  StartStone.m
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "StartStone.h"
#import "Utilities.h"

@implementation StartStone

@synthesize args;

- (NSArray *)arguments;
{ 
	NSMutableArray *list = [NSMutableArray arrayWithObject:[database name]];
	if (args) {
		[list addObjectsFromArray:args];
	}
	return list;
}

- (NSString *)binName;
{
	return @"startstone";
}

- (void)done;
{
	[database setIsRunning:YES];
//	[self delayFor:2.0];	//	give time for output so it isn't intermixed with other output
	[super done];
 }

- (void)main;
{
	[appController taskProgress:@"\n"];	
	[super main];
}

@end
