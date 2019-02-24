//
//  StartStone.m
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "StartStone.h"
#import "Utilities.h"

@implementation StartStone

- (NSArray *)arguments;
{ 
	NSMutableArray *list = [NSMutableArray arrayWithObject:[self.database name]];
	if (self.args) {
		[list addObjectsFromArray:self.args];
	}
	return list;
}

- (NSString *)binName {
	return @"startstone";
}

- (void)done {
	[self.database setIsRunning:YES];
//	[self delayFor:2.0];	//	give time for output so it isn't intermixed with other output
	[super done];
 }

- (void)main {
	[appController taskProgress:@"\n"];	
	[super main];
}

@end
