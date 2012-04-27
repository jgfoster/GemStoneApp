//
//  Version.m
//  GemStone
//
//  Created by James Foster on 4/22/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "NSFileManager+DirectoryLocations.h"
#import "Version.h"
#import "AppController.h"

@interface Version ()
@end

@implementation Version

@synthesize isInstalled;
@synthesize version;
@synthesize date;

- (NSString *)dateString;
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
	return [dateFormatter stringFromDate:date];
}

BOOL		isInstalled;
NSString	*version;
NSDate		*date;

- (void)encodeWithCoder:(NSCoder *)encoder;
{
	[encoder encodeBool:isInstalled forKey:@"isInstalled"];
	[encoder encodeObject:version forKey:@"version"];
	[encoder encodeObject:date forKey:@"date"];
}

- (id) initWithCoder: (NSCoder *)coder
{
	if (self = [super init])
	{
		isInstalled = [coder decodeBoolForKey:@"isInstalled"];
		version = [coder decodeObjectForKey:@"version"];
		date = [coder decodeObjectForKey:@"date"];
	}
	return self;
}

- (NSNumber *)isInstalledNumber;
{
	return [NSNumber numberWithBool: isInstalled];
}

- (NSString *)productPath;
{
	NSString *appSupDir = [[NSFileManager defaultManager] applicationSupportDirectory];
	NSMutableString *path = [NSMutableString stringWithString:appSupDir];
	[path appendString:@"/GemStone64Bit"];
	[path appendString:version];
	[path appendString:@"-i386.Darwin"];
	return path;
}

- (BOOL)remove:(NSError *__autoreleasing *)error;
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *productPath = [self productPath];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:productPath];
	NSString *file;
	NSDictionary *attributes = [NSDictionary 
								dictionaryWithObject:[NSNumber numberWithUnsignedLong:0777U] 
								forKey:NSFilePosixPermissions];
	while (file = [dirEnum nextObject]) {
		NSString *path = [[productPath stringByAppendingString:@"/"]stringByAppendingString:file];
		BOOL isDirectory;
		BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
		if (exists && isDirectory) {
			if (![fileManager setAttributes:attributes ofItemAtPath:path error:error]) {
				return NO;
			}
		}
	}
	return [[NSFileManager defaultManager] removeItemAtPath:[self productPath] error:error];
}

- (void)updateIsInstalled;
{
	BOOL isDirectory;
	BOOL exists = [[NSFileManager defaultManager] 
				   fileExistsAtPath:[self productPath] 
				   isDirectory:&isDirectory];
	isInstalled = exists && isDirectory;
}

- (NSString *)zippedFileName;
{
	NSMutableString *string = [NSMutableString new];
	[string appendString:@"GemStone64Bit"];
	[string appendString:version];
	[string appendString:@"-i386.Darwin.zip"];
	return string;
}

@end
