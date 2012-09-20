//
//  StopStone.m
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "StopStone.h"
#import "Utilities.h"

@implementation StopStone

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			[database name],
			@"DataCurator",
			@"swordfish",
			@"-i",
			nil];
}

- (void)done;
{
	[database setIsRunning:NO];
	[database archiveCurrentLogFiles];
	[database archiveCurrentTransactionLogs];
	[super done];
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/stopstone", [database gemstone]];
}

- (void)main;
{
	[notificationCenter postNotificationName:kTaskProgress object:@"\nStopping Stone . . .\n"];	
	[super main];
}

@end
