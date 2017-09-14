//
//  WaitStone.m
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "WaitStone.h"

@implementation WaitStone

@synthesize isReady = _isReady;

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
			[self.database name],
			@"-1",
			nil];
}

- (NSString *)binName;
{
	return @"waitstone";
}

- (void)done;
{
	_isReady = YES;
	[super done];
}

- (void)doneWithError:(int)statusCode;
{
	_isReady = NO;
	[super doneWithError:0];
}

- (void)progress:(NSString *)aString;
{
	//	override to prevent reporting
}

- (void)setDatabase:(Database *)aDatabase;
{
	[super setDatabase:aDatabase];
}

@end
