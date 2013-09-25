//
//  Terminal.m
//  GemStone
//
//  Created by James Foster on 9/24/13.
//  Copyright (c) 2013 VMware Inc. All rights reserved.
//

#import "Terminal.h"
#import "Utilities.h"

@implementation Terminal

- (NSArray *)arguments;
{
	return [NSArray arrayWithObjects:
			@"-b",
			@"com.apple.Terminal",
			@"-n",
			[database directory],
			nil];
}

- (NSMutableDictionary *)environment;
{
	NSMutableDictionary *environment = [super environment];
	NSString *path = [environment valueForKey:@"PATH"];
	path = [NSString stringWithFormat:@"%@/bin:%@", [database gemstone], path];
	[environment setValue:path forKey:@"PATH"];
	for (NSString* key in [environment allKeys]) {
		if ([key rangeOfString:@"DYLD_"].location != NSNotFound) {
			[environment removeObjectForKey:key];
		}
	}
	return environment;
}

- (NSString *)launchPath;
{
	return @"/usr/bin/open";
}

@end
