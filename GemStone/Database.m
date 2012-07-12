//
//  Database.m
//  GemStone
//
//  Created by James Foster on 5/17/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "AppController.h"
#import "Database.h"
#import "GSList.h"
#import "LogFile.h"
#import "Setup.h"
#import "Utilities.h"
#import "Version.h"
#import "WaitStone.h"

@implementation Database

// following are part of the DataModel handled by Core Data
@dynamic indexInArray;
@dynamic isRunningCode;
@dynamic lastStartDate;
@dynamic name;
@dynamic netLDI;
@dynamic spc_mb;
@dynamic version;


- (void)archiveCurrentLogFiles;
{
	NSError  *error = nil;
	NSString *path = [NSString stringWithFormat:@"%@/log", [self directory]];
	NSArray  *baseList = [[self name] componentsSeparatedByString:@"_"];
	NSUInteger baseListCount = [baseList count];
	
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSArray *thisList = [file componentsSeparatedByString:@"_"];
		int j = -1;
		for (int i = 0; i == j + 1 && i < [thisList count] && i < baseListCount; ++i) {
			if (NSOrderedSame == [[baseList objectAtIndex:i] compare:[thisList objectAtIndex:i]]) {
				j = i;
			}
		}
		if (j + 1 == baseListCount) {
			NSString *target = [NSString stringWithFormat:@"%@/archive/%@", path, file];
			[fileManager removeItemAtPath:target error:nil];
			if (![fileManager 
				  moveItemAtPath:[NSString stringWithFormat:@"%@/%@", path, file]
				  toPath:target
				  error:&error]) {
				AppError(@"Unable to move %@/%@ because %@", path, file, [error description]);
			}
		}
	}
}

- (void)archiveCurrentTransactionLogs;
{
	NSError *error = nil;
	NSString *dataPath = [NSString stringWithFormat:@"%@/data", [self directory]];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:dataPath];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSRange first = [file rangeOfString:@"tranlog"];
		NSRange last  = [file rangeOfString:@".dbf"];
		if (first.location == 0 && first.length == 7 && last.location == [file length] - 4) {
			NSString *source = [NSString stringWithFormat:@"%@/%@", dataPath, file];
			NSString *target = [NSString stringWithFormat:@"%@/archive/%@", dataPath, file];
			[fileManager removeItemAtPath:target error:nil];
			if (![fileManager moveItemAtPath:source toPath:target error:&error]) {
				AppError(@"Unable to move %@ because %@", source, [error description]);
			}
		}
	}
}

- (BOOL)canInitialize;		// bound to Initialize buttons on MainMenu
{
	return [self canStart];
}

- (BOOL)canStart;
{
	return [self isVersionDefined] && ![self isRunning];
}

- (void)createConfigFile;
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
	if (![fileManager 
			createFileAtPath:path 
			contents:[string dataUsingEncoding:NSUTF8StringEncoding] 
			attributes:nil]) {
		AppError(@"Unable to create config file at %@", path);
	};
}

- (void)createDirectories;
{
	[self createDirectory:@"conf"];
	[self createDirectory:@"data"];
	[self createDirectory:@"data/archive"];
	[self createDirectory:@"log"];
	[self createDirectory:@"log/archive"];
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

- (void)deleteFilesIn:(NSString *)aString;
{
	NSString *path = [NSString stringWithFormat:@"%@/%@", [self directory], aString];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSError  *error = nil;
		NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, file];
		if (![fileManager removeItemAtPath:fullPath error:&error]) {
			AppError(@"unable to delete %@ because %@", fullPath, [error description]);
		};
	}
	[notificationCenter postNotificationName:kDababaseInfoChanged object:nil];
}

- (void)deleteOldLogFiles;
{
	[self deleteFilesIn:@"log/archive"];
}

- (void)deleteOldTranLogs;
{
	[self deleteFilesIn:@"data/archive"];
}

- (NSString *)descriptionOfFilesIn:(NSString *)aString;
{
	NSString *path = [NSString stringWithFormat:@"%@/%@/archive", [self directory], aString];
	NSUInteger count = 0;
	NSUInteger size = 0;
	
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSError  *error = nil;
		NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, file];
		NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPath error:&error];
		if (error) {
			AppError(@"Unable to obtain attributes of %@ because %@", fullPath, [error description]);
		}
		count = count + 1;
		size = size + [[attributes valueForKey:NSFileSize] unsignedLongValue];
	}
	NSUInteger kbSize = size / 1024;
	NSUInteger mbSize = kbSize / 1024;
	return 9 < mbSize ?
		[NSString stringWithFormat:@"%lu files, %lu MB", count, mbSize] :
		[NSString stringWithFormat:@"%lu files, %lu KB", count, kbSize];
}

- (NSString *)descriptionOfOldLogFiles;
{
	return [self descriptionOfFilesIn:@"log"];
}
- (NSString *)descriptionOfOldTranLogs;
{
	return [self descriptionOfFilesIn:@"data"];
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
		NSArray *versions = [[NSApp delegate] versionList];
		Version *aVersion = [versions objectAtIndex:0];
		version = aVersion.name;
		for (Version *each in versions) {
			if ([version compare:each.name]== NSOrderedAscending) {
				version = each.name;
			}
		}
		[self installBaseExtent];
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
	[[NSApp delegate] startTaskProgressSheetAndAllowCancel:NO];
	[notificationCenter postNotificationName:kTaskProgress object:@"Copying extent . . ."];
	[self archiveCurrentTransactionLogs];
	NSString *source = [NSString stringWithFormat:@"%@/bin/%@", [self gemstone], aString];
	BOOL success = [fileManager copyItemAtPath:source toPath:target error:&error];
	if (!success) {
		AppError(@"copy from %@ to %@ failed because %@!", source, target, [error description]);
	}
	NSDictionary *attributes = [NSDictionary 
								dictionaryWithObject:[NSNumber numberWithInt:0600] 
								forKey:NSFilePosixPermissions];
	success = [fileManager setAttributes:attributes ofItemAtPath:target error:&error];
	if (!success) {
		AppError(@"Unable to change permissions of %@ because %@", target, [error description]);
	}
	lastStartDate = nil;
	[[NSApp delegate] taskFinished];
}

- (void)installGlassExtent;
{
	[self installExtent:@"extent0.seaside.dbf"];
}

- (BOOL)isRunning;
{
	return [isRunningCode boolValue];
}

- (NSString *)isRunningString;
{
	return [self isRunning] ? @"yes" : @"no";
}

- (BOOL)isVersionDefined;
{
	return 0 < [version length];
}

- (NSArray *)logFiles;
{
	NSMutableArray *list = [NSMutableArray array];
	NSString *path = [NSString stringWithFormat:@"%@/log", [self directory]];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		if (1 < [[file pathComponents] count]) {
			[dirEnum skipDescendents];
			continue;
		}
		if (NSOrderedSame == [@".log" compare:[file substringFromIndex:[file length]-4]]) {
			NSError *error = nil;
			NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, file];
			NSDictionary *dict = [fileManager attributesOfItemAtPath:fullPath error:&error];
			if (error) {
				AppError(@"Unable to obtain attributes of %@ because %@", fullPath, [error description]);
			}
			NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:dict];
			[attributes setValue:file forKey:@"name"];
			[attributes setValue:fullPath forKey:@"path"];
			[attributes setValue:[self name] forKey:@"stone"];
			[list addObject:[LogFile logFileFromDictionary:attributes]];
		}
	}
	return list;
}

- (NSString *)name;
{
	if ([name length]) return name;
	return [NSString stringWithFormat:@"gs64stone%@", [self identifier]];
}

- (NSString *)netLDI;
{
	if ([netLDI length]) return netLDI;
	return [NSString stringWithFormat:@"netldi%@", [self identifier]];
}

- (void)open;
{
	[[NSWorkspace sharedWorkspace] openFile:[self directory]];
}

- (void)restore;
{
	NSLog(@"restore");
}

- (void)setIsRunning:(BOOL)aBool;
{
	isRunningCode = [NSNumber numberWithBool:aBool];
	if (aBool) {
		lastStartDate = [NSDate date];
	}
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
	//
	[self createConfigFile];
	[self archiveCurrentLogFiles];
	[notificationCenter postNotificationName:kDatabaseStartRequest object:self];
}

- (void)stop;
{
	[notificationCenter postNotificationName:kDatabaseStopRequest object:self];
}

- (NSString *)version;
{
	if (![version length]) return nil;
	return version;
}

@end
