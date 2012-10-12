//
//  Statmonitor.m
//  GemStone
//
//  Created by James Foster on 7/12/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Statmonitor.h"
#import "Utilities.h"

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

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/statmonitor", [database gemstone]];
}

//	override to leave task running
- (void)main;
{
	@try {
		[appController taskProgress:@"\nStarting Statmonitor . . .\n"];	
		[self startTask];
		[self doRunLoopFor:1.0];
		[appController taskProgress:@"\nStatmonitor started!\n"];	
	}
	@catch (NSException *exception) {
		NSLog(@"Exception in task: %@", exception);
	}
	@finally {
		//		<#statements#>
	}
}

@end
