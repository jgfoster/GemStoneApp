//
//  StartStone.m
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
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

- (void)done;
{
	[database setIsRunning:YES];
	[super done];
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/startstone", [database gemstone]];
}

- (void)main;
{
	[appController taskProgress:@"\n"];	
	[super main];
}

@end
