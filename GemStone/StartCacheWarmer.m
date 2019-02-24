//
//  StartCacheWarmer.m
//  GemStone
//
//  Created by James Foster on 6/11/13.
//  Copyright (c) 2013 VMware Inc. All rights reserved.
//

#import "StartCacheWarmer.h"

@implementation StartCacheWarmer

- (NSArray *)arguments {
	NSString *stoneName = [self.database name];
	return [NSArray arrayWithObjects:
			@"-d",
			@"-L",
			@"log",
			@"-s",
			stoneName,
			nil];
}

- (NSString *)binName {
	return @"startcachewarmer";
}

@end
