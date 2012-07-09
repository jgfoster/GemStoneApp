//
//  Database.m
//  GemStone
//
//  Created by James Foster on 5/17/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "AppController.h"
#import "Database.h"
#import "Setup.h"
#import "Utilities.h"

@implementation Database

@dynamic indexInArray;
@dynamic lastStartDate;
@dynamic name;
@dynamic spc_mb;
@dynamic version;

- (BOOL)canEditVersion;
{
	return nil == lastStartDate;
}

- (BOOL)canInitialize;		// bound to Initialize buttons on MainMenu
{
	return [self isVersionDefined];
}

- (BOOL)canRestore;
{
	return [self isVersionDefined] && NO;
}

- (BOOL)canStart;
{
	return [self isVersionDefined];
}

- (BOOL)canStop;
{
	return YES;
}

- (BOOL)createConfigFile;
{
	NSString *directory = [self directory];
	NSString *path = [NSString stringWithFormat:@"%@/conf/system.conf", directory];
	NSMutableString *string = [NSMutableString new];
	[string appendFormat: @"DBF_EXTENT_NAMES = \"%@/data/extent0.dbf\";\n", directory];
	[string appendString: @"STN_TRAN_FULL_LOGGING = TRUE;\n"];
	[string appendFormat: @"STN_TRAN_LOG_DIRECTORIES = \"/%@/data/\", \n", directory];
	[string appendFormat: @"	\"%@/data/\";\n", [self directory]];
	[string appendString: @"STN_TRAN_LOG_SIZES = 100, 100;\n"];
	[string appendString: @"KEYFILE = \"$GEMSTONE/seaside/etc/gemstone.key\";\n"];
	[string appendFormat: @"SHR_PAGE_CACHE_SIZE_KB = %lu;\n", [self spc_kb]];
	return [fileManager 
			createFileAtPath:path 
			contents:[string dataUsingEncoding:NSUTF8StringEncoding] 
			attributes:nil];
}

- (void)createDirectories;
{
	[self createDirectory:@"conf"];
	[self createDirectory:@"data"];
	[self createDirectory:@"logs"];
	[self createDirectory:@"stat"];
	[self createLocksDirectory];
}

- (void)createDirectory:(NSString *)aString;
{
	NSString *path = [NSString stringWithFormat:@"%@/%@", [self directory], aString];
	NSError *error = nil;
	if ([fileManager
		 createDirectoryAtPath:path
		 withIntermediateDirectories:YES
		 attributes:nil
		 error:&error]) return;
	AppError(@"Unable to create %@ because %@!", path, [error description]);
}

- (void)createLocksDirectory;
{
	NSError *error;
	// this needs to point to something
	NSString *localLink = [NSString stringWithFormat:@"%@/locks", [self directory]];
	// previous installations might have created this directory
	NSString *traditional = @"/opt/gemstone/locks";
	// if traditional path is not present, we will use application support directory
	NSString *alternate = [NSString stringWithFormat:@"%@/locks", basePath];
	
	// try linking to traditional location
	BOOL isDirectory;
	BOOL exists = [fileManager
				   fileExistsAtPath:traditional 
				   isDirectory:&isDirectory];
	if (exists && isDirectory) {
		if ([fileManager
			 createSymbolicLinkAtPath:localLink 
			 withDestinationPath:traditional 
			 error:&error]) return;
		AppError(@"unable to link %@ to %@ because %@", localLink, traditional, [error description]);
	};
	
	// try linking alternate location
	exists = [fileManager
			  fileExistsAtPath:alternate 
			  isDirectory:&isDirectory];
	if (exists && !isDirectory) {
		AppError(@"%@ is not a directory!", alternate);
	}
	if (!exists) {
		if (![fileManager
			 createDirectoryAtPath:alternate
			 withIntermediateDirectories:YES
			 attributes:nil
			 error:&error]) {
			AppError(@"unable to create %@ because %@", alternate, [error description]);
		}
	}
	if ([fileManager
		 createSymbolicLinkAtPath:localLink
		 withDestinationPath:alternate
		 error:&error]) return;
	AppError(@"unable to link %@ to %@ because %@", localLink, alternate, [error description]);
}

- (void)deleteAll;
{
	NSString *path = [self directory];
	NSError *error = nil;
	if ([fileManager removeItemAtPath:path error:&error]) return;
	AppError(@"unable to delete %@ because %@", path, [error description]);
}

- (void)deleteTransactionLogs;
{
	NSError *error = nil;
	NSString *dataPath = [NSString stringWithFormat:@"%@/data", [self directory]];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:dataPath];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSRange first = [file rangeOfString:@"tranlog"];
		NSRange last  = [file rangeOfString:@".dbf"];
		if (first.location == 0 && first.length == 7 && last.location == [file length] - 4) {
			NSString *path = [[dataPath stringByAppendingString:@"/"]stringByAppendingString:file];
			if (![fileManager removeItemAtPath:path error:&error]) {
				AppError(@"Unable to remove %@ because %@", path, [error description]);
			}
		}
		
	}
}

- (NSString *)directory;
{
	return [NSString stringWithFormat: @"%@/db%@", basePath, [self identifier]];
}

- (NSString *)gemstone;
{
	NSString *path = [NSString stringWithFormat: @"%@/GemStone64Bit%@-i386.Darwin", basePath, [self version]];
	return path;
}

- (NSNumber *)identifier;
{
	if (![identifier intValue]) {
		identifier = [[[NSApp delegate] setup] newDatabaseIdentifier];
		[self createDirectories];
	}
	return identifier;
}

- (void)installBaseExtent;
{
	[self installExtent:@"extent0.dbf"];
}

- (void)installExtent: (NSString *) aString;
{
	NSError *error = nil;
	NSString *target = [NSString stringWithFormat:@"%@/data/extent0.dbf", [self directory]];
	if ([fileManager fileExistsAtPath:target]) {
		if (lastStartDate) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setAlertStyle:NSCriticalAlertStyle];
			[alert setMessageText:@"Replace existing repository?"];
			[alert setInformativeText:@"All data in the existing repository will be lost!"];
			[alert addButtonWithTitle:@"Cancel"];
			[alert addButtonWithTitle:@"Replace"];
			NSInteger answer = [alert runModal];
			if (NSAlertSecondButtonReturn != answer) {
				return;
			}
		}
		if (![fileManager removeItemAtPath:target error:&error]) {
			AppError(@"unable to delete %@ because %@", target, [error description]);
		}
	}
	[self deleteTransactionLogs];
	NSString *source = [NSString stringWithFormat:@"%@/bin/%@", [self gemstone], aString];
	if ([fileManager copyItemAtPath:source toPath:target error:&error]) {
		NSDictionary *attributes = [NSDictionary 
									dictionaryWithObject:[NSNumber numberWithInt:0600] 
									forKey:NSFilePosixPermissions];
		BOOL success = [fileManager
		 setAttributes:attributes
		 ofItemAtPath:target
		 error:&error];
		if (success) {
			lastStartDate = nil;
			return;
		}
		AppError(@"Unable to change permissions of %@ because %@", target, [error description]);
	}
	AppError(@"copy from %@ to %@ failed because %@!", source, target, [error description]);
}

- (void)installGlassExtent;
{
	[self installExtent:@"extent0.seaside.dbf"];
}

- (BOOL)isVersionDefined;
{
	return 0 < [version length];
}

- (NSString *)name;
{
	[self identifier];
	if (![name length]) return nil;
	return name;
}

- (NSString *)nameOrDefault;
{
	if (![name length]) return @"gs64stone";
	return name;
}

- (void)restore;
{
	NSLog(@"restore");
}

- (void)setVersion:(NSString *)aString;
{
	if (version == aString) return;
	version = aString;
	[self installBaseExtent];
}

- (unsigned long)spc_kb;
{
	if (![spc_mb intValue]) return 131072;
	return [[self spc_mb] unsignedLongValue] * 1024;
}

- (NSNumber *)spc_mb;
{
	if (![spc_mb intValue]) return nil;
	return spc_mb;
}

- (void)start;
{
	if (![self createConfigFile]) return;
	[[NSNotificationCenter defaultCenter] postNotificationName:kDatabaseStartRequest object:self];
}

- (void)stop;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kDatabaseStopRequest object:self];
}

- (NSString *)version;
{
	if (![version length]) return nil;
	return version;
}

@end
