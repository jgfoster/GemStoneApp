//
//  StartStone.m
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "StartStone.h"

@implementation StartStone

- (NSArray *)arguments;
{ 
	NSMutableArray *list = [NSMutableArray arrayWithObject:[database name]];
	if ([database restorePath]) {
		[list addObject:@"-R"];
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

@end
