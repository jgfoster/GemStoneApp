//
//  Setup.m
//  GemStone
//
//  Created by James Foster on 5/22/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Setup.h"
#import "Utilities.h"

@implementation Setup

@dynamic lastDatabaseIdentifier;
@dynamic taskCloseWhenDoneCode;
@dynamic versionsDownloadDate;

- (id)initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context;
{
	if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
		self.lastDatabaseIdentifier = [NSNumber numberWithInt:0];
		self.taskCloseWhenDoneCode  = [NSNumber numberWithBool:YES];
		self.versionsDownloadDate	= nil;
	}
	return self;
}

- (NSNumber *)newDatabaseIdentifier;
{
	self.lastDatabaseIdentifier = [NSNumber numberWithInt:([self.lastDatabaseIdentifier intValue] + 1)];
	return self.lastDatabaseIdentifier;
}

@end
