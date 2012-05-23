//
//  Setup.m
//  GemStone
//
//  Created by James Foster on 5/22/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Setup.h"


@implementation Setup

@dynamic versionsDownloadDate;
@dynamic lastDatabaseIdentifier;

- (NSNumber *)newDatabaseIdentifier;
{
	self.lastDatabaseIdentifier = [NSNumber numberWithInt:([self.lastDatabaseIdentifier intValue] + 1)];
	return self.lastDatabaseIdentifier;
}

@end
