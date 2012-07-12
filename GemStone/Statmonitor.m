//
//  Statmonitor.m
//  GemStone
//
//  Created by James Foster on 7/12/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Statmonitor.h"

@implementation Statmonitor

- (NSArray *)arguments;
{ 
	NSDateFormatter *formatter = [NSDateFormatter new];
	[formatter setDateFormat:@"yyyy-MM-dd-HH-mm"];
	NSString *dateString = [formatter stringFromDate:[NSDate date]];
	NSString *path = [NSString stringWithFormat:@"%@/stat/statmon_%@",[database directory], dateString];
	return [NSArray arrayWithObjects: 
			[database name],
			@"-f",
			path,
			@"-h",
			@"24",
			@"-r",
			@"-z",
			nil];
}

- (void)done;
{
	[super done];
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/statmonitor", [database gemstone]];
}

@end
