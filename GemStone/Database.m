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
	return NO;
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
	return [[NSFileManager defaultManager] 
			createFileAtPath:path 
			contents:[string dataUsingEncoding:NSUTF8StringEncoding] 
			attributes:nil];
}

- (BOOL)createDirectories;
{
	return YES 
		&& [self createDirectory:@"conf"]
		&& [self createDirectory:@"data"]
		&& [self createDirectory:@"logs"]
		&& [self createDirectory:@"stat"]
		&& [self createLocksDirectory]
		;
}

- (BOOL)createDirectory:(NSString *)aString;
{
	NSString *path = [NSString stringWithFormat:@"%@/%@", [self directory], aString];
	NSError *error = nil;
	if ([[NSFileManager defaultManager]
		 createDirectoryAtPath:path
		 withIntermediateDirectories:YES
		 attributes:nil
		 error:&error]) return YES;
	NSLog(@"Unable to create %@ because %@!", path, [error description]);
	return NO;
}

- (BOOL)createLocksDirectory;
{
	NSError *error;
	// this needs to point to something
	NSString *localLink = [NSString stringWithFormat:@"%@/locks", [self directory]];
	// previous installations might have created this directory
	NSString *traditional = @"/opt/gemstone/locks";
	// if traditional path is not present, we will use application support directory
	NSString *alternate = [NSString stringWithFormat:@"%@/locks", [[NSApp delegate] basePath]];
	
	// try linking to traditional location
	BOOL isDirectory;
	BOOL exists = [[NSFileManager defaultManager] 
				   fileExistsAtPath:traditional 
				   isDirectory:&isDirectory];
	if (exists && isDirectory) {
		if ([[NSFileManager defaultManager]
			 createSymbolicLinkAtPath:localLink 
			 withDestinationPath:traditional 
			 error:&error]) {
			return YES;
		}
		NSLog(@"unable to link %@ to %@ because %@", localLink, traditional, [error description]);
		return NO;
	};
	
	// try linking alternate location
	exists = [[NSFileManager defaultManager] 
			  fileExistsAtPath:alternate 
			  isDirectory:&isDirectory];
	if (exists && !isDirectory) {
		NSLog(@"%@ is not a directory!", alternate);
		return NO;
	}
	if (!exists) {
		if (![[NSFileManager defaultManager]
			 createDirectoryAtPath:alternate
			 withIntermediateDirectories:YES
			 attributes:nil
			 error:&error]) {
			NSLog(@"unable to create %@ because %@", alternate, [error description]);
			return NO;
		}
	}
	if ([[NSFileManager defaultManager]
		 createSymbolicLinkAtPath:localLink
		 withDestinationPath:alternate
		 error:&error]) {
		return YES;
	}
	NSLog(@"unable to link %@ to %@ because %@", localLink, alternate, [error description]);
	return NO;
}

- (void)deleteAll;
{
	NSString *path = [self directory];
	NSError *error = nil;
	if ([[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
		return;
	}
	NSLog(@"unable to delete %@ because %@", path, [error description]);
}

- (NSString *)directory;
{
	return [NSString stringWithFormat: @"%@/db%@", [[NSApp delegate] basePath], [self identifier]];
}

- (NSString *)gemstone;
{
	NSString *path = [NSString stringWithFormat: @"%@/GemStone64Bit%@-i386.Darwin", [[NSApp delegate] basePath], [self version]];
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
	if ([[NSFileManager defaultManager] fileExistsAtPath:target]) {
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
		if (![[NSFileManager defaultManager] removeItemAtPath:target error:&error]) {
			NSLog(@"unable to delete %@ because %@", target, [error description]);
			return;
		}
	}
	NSString *source = [NSString stringWithFormat:@"%@/bin/%@", [self gemstone], aString];
	if ([[NSFileManager defaultManager] copyItemAtPath:source toPath:target error:&error]) {
		NSDictionary *attributes = [NSDictionary 
									dictionaryWithObject:[NSNumber numberWithInt:0600] 
									forKey:NSFilePosixPermissions];
		BOOL success = [[NSFileManager defaultManager]
		 setAttributes:attributes
		 ofItemAtPath:target
		 error:&error];
		if (success) {
			lastStartDate = nil;
			return;
		}
		NSLog(@"Unable to change permissions of %@ because %@", target, [error description]);
		return;
	}
	NSLog(@"copy from %@ to %@ failed because %@!", source, target, [error description]);
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
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName:kDatabaseStartRequest 
	 object:self];
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
