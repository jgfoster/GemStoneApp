//
//  StartCacheWarmer.m
//  GemStone
//
//  Created by James Foster on 6/11/13.
//  Copyright (c) 2013 VMware Inc. All rights reserved.
//

#import "StartCacheWarmer.h"

@implementation StartCacheWarmer

- (NSArray *)arguments;
{
	NSString *stoneName = [database name];
	return [NSArray arrayWithObjects:
			@"-d",
			@"-L",
			@"log",
			@"-s",
			stoneName,
			nil];
}

- (NSString *)launchPath;
{
	return [NSString stringWithFormat:@"%@/bin/startcachewarmer", [database gemstone]];
}

@end
