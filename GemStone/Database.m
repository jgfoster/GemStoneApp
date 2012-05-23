//
//  Database.m
//  GemStone
//
//  Created by James Foster on 5/17/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Database.h"
#import "AppController.h"
#import "Setup.h"

@implementation Database

@dynamic indexInArray;
@dynamic name;
@dynamic spc_mb;
@dynamic version;

- (void)deleteAll;
{
	NSLog(@"deleteAll");
}

- (NSNumber *)identifier;
{
	if (![identifier intValue]) {
		identifier = [[[NSApp delegate] setup] newDatabaseIdentifier];
	}
	return identifier;
}

- (void)installBaseExtent;
{
	NSLog(@"installBaseExtent");
}

- (void)installGlassExtent;
{
	NSLog(@"installGlassExtent");
}

- (BOOL)isRunning;
{
	return NO;
}

- (NSString *)name;
{
	if (![name length]) return nil;
	return name;
}

- (NSNumber *)spc_mb;
{
	if (![spc_mb intValue]) return nil;
	return spc_mb;
}

- (void)start;
{
	NSLog(@"start");
}

- (NSString *)version;
{
	if (![version length]) return nil;
	return version;
}

@end
