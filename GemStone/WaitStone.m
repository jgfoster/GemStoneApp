//
//  WaitStone.m
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "WaitStone.h"

@implementation WaitStone

@synthesize name;
@synthesize isReady;

+ (BOOL)isStoneRunningForDatabase:(Database *)database;
{
	WaitStone *task = [self forDatabase:database];
	[task main];
	return [task isReady];
}

+ (BOOL)isNetLdiRunningForDatabase:(Database *)database;
{
	WaitStone *task = [self forDatabase:database];
	[task setName:[database netLDI]];
	[task main];
	return [task isReady];
}

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			name,
			@"-1",
			nil];
}

- (void)done;
{
	isReady = YES;
}

- (void)doneWithError:(int)statusCode;
{
	isReady = NO;
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/waitstone", [database gemstone]];
}

- (void)setDatabase:(Database *)aDatabase;
{
	[self setName:[aDatabase name]];
	[super setDatabase:aDatabase];
}

@end
