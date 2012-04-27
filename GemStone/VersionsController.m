//
//  VersionsController.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "VersionsController.h"

@implementation VersionsController

@synthesize versions;

- (id)init {
	self = [super init];
	if (self) {

	}
	return self;
}

- (void)windowDidLoad
{
	NSLog(@"windowDidLoad");
}

- (NSString *)windowNibName
{
	return @"Versions";
}

@end
