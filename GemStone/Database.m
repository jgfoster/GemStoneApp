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
#import "NSFileManager+DirectoryLocations.h"

@implementation Database

@dynamic indexInArray;
@dynamic name;
@dynamic spc_mb;
@dynamic version;

- (BOOL)canInitialize;
{
	return version != nil;
}

- (BOOL)canRestore;
{
	return NO;
}

- (BOOL)canStart;
{
	return NO;
}

- (BOOL)canStop;
{
	return NO;
}

- (NSString *)dataDirectory;
{
	NSString *appSupDir = [[NSFileManager defaultManager] applicationSupportDirectory];
	NSString *path = [NSString stringWithFormat: @"%@/db%@", appSupDir, [self identifier]];
	
	BOOL isDirectory;
	if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
		if (isDirectory) return path;
		NSLog(@"%@ is not a directory!", path);
		return nil;
	}
	NSError *error = nil;
	BOOL success = [[NSFileManager defaultManager]
					createDirectoryAtPath:path
					withIntermediateDirectories:YES
					attributes:nil
					error:&error];
	if (!success) 
	{
		NSLog(@"Unable to create %@ because %@!", path, [error description]);
		return nil;
	}	return path;
}

- (void)deleteAll;
{
	NSString *path = [self dataDirectory];
	NSError *error = nil;
	if ([[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
		return;
	}
	NSLog(@"unable to delete %@ because %@", path, [error description]);
}

- (NSString *)gemstone;
{
	NSString *appSupDir = [[NSFileManager defaultManager] applicationSupportDirectory];
	NSString *path = [NSString stringWithFormat: @"%@/GemStone64Bit%@-i386.Darwin", appSupDir, [self version]];
	return path;
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
	NSString *source = [NSString stringWithFormat:@"%@/bin/extent0.dbf", [self gemstone]];
	NSString *target = [NSString stringWithFormat:@"%@/extent0.dbf", [self dataDirectory]];
	NSError *error = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:target]) {
		if (![[NSFileManager defaultManager] removeItemAtPath:target error:&error]) {
			NSLog(@"unable to delete %@ because %@", target, [error description]);
			return;
		}
	}
	if ([[NSFileManager defaultManager] copyItemAtPath:source toPath:target error:&error]) {
		return;
	}
	NSLog(@"copy from %@ to %@ failed because %@!", source, target, [error description]);
}

- (void)installGlassExtent;
{
	NSLog(@"installGlassExtent");
}

- (NSString *)name;
{
	if (![name length]) return nil;
	return name;
}

- (void)restore;
{
	NSLog(@"restore");
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

- (void)stop;
{
	NSLog(@"stop");
}

- (NSString *)version;
{
	if (![version length]) return nil;
	return version;
}

@end
