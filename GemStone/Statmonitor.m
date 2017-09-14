//
//  Statmonitor.m
//  GemStone
//
//  Created by James Foster on 7/12/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Statmonitor.h"
#import "Utilities.h"

@implementation Statmonitor

- (NSArray *)arguments;
{ 
	NSDateFormatter *formatter = [NSDateFormatter new];
	[formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
	NSString *dateString = [formatter stringFromDate:[NSDate date]];
	NSString *path = [NSString stringWithFormat:@"%@/stat/statmon_%@",[self.database directory], dateString];
	return [NSArray arrayWithObjects: 
			[self.database name],
			@"-f",
			path,
			@"-h",
			@"24",
			@"-r",
			@"-z",
			nil];
}

- (NSString *)binName;
{ 
	return @"statmonitor";
}

//	override to leave task running
- (void)main;
{
	@try {
		[appController taskProgress:@"\nStarting Statmonitor . . .\n"];	
		[self startTask];
		[self delayFor:1.0];	//	give time for output so it isn't intermixed with other output
		[appController taskProgress:@"\nStatmonitor started!\n"];	
	}
	@catch (NSException *exception) {
		NSLog(@"Exception in task: %@", exception);
	}
	@finally {
		//
	}
}

@end
