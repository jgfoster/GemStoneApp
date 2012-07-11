//
//  StopStone.m
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "StopStone.h"

@implementation StopStone

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			[database name],
			@"DataCurator",
			@"swordfish",
			nil];
}

- (void)done;
{
	[database setIsRunning:NO];
	[super done];
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/stopstone", [database gemstone]];
}

@end
