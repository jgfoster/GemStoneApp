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
	return [NSArray arrayWithObjects: 
			[database name],
			nil];
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
