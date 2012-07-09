//
//  Version.m
//  GemStone
//
//  Created by James Foster on 4/22/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Utilities.h"
#import "Version.h"

@interface Version ()
@end

@implementation Version

@dynamic isInstalledCode;
@dynamic name;
@dynamic date;
@dynamic indexInArray;

- (BOOL)isActuallyInstalled;
{
	BOOL isDirectory;
	BOOL exists = [fileManager
				   fileExistsAtPath:[self productPath] 
				   isDirectory:&isDirectory];
	return exists && isDirectory;
}

- (BOOL)isInstalled;
{
	return [self.isInstalledCode boolValue];
}

- (NSString *)productPath;
{
	return [NSString stringWithFormat:@"%@/GemStone64Bit%@-i386.Darwin", basePath, self.name];
}

- (void)remove;
{
	NSError *error = nil;
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
			if (![fileManager setAttributes:attributes ofItemAtPath:path error:&error]) {
				AppError(@"Unable to set directory permissions for %@ because %@", path, [error description]);
			}
		}
	}
	if ([fileManager removeItemAtPath:[self productPath] error:&error]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kRemoveVersionDone object:self];
	} else {
		AppError(@"Unable to remove %@ because %@", [self productPath], [error description]);
	}
}

- (void)setIsInstalledCode:(NSNumber *)aNumber;
{
	if (isInstalledCode == aNumber) return;
	if ([self isActuallyInstalled] == [aNumber boolValue]) {
		isInstalledCode = aNumber;
		return;
	}
	if ([aNumber boolValue]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kDownloadRequest object:self];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:kRemoveRequest object:self];
	}
}

- (void)updateIsInstalled;
{
	NSNumber *code = [NSNumber numberWithBool:[self isActuallyInstalled]];
	if (code != isInstalledCode) {
		self.isInstalledCode = code;
	}
}

- (NSString *)zippedFileName;
{
	NSMutableString *string = [NSMutableString new];
	[string appendString:@"GemStone64Bit"];
	[string appendString:name];
	[string appendString:@"-i386.Darwin.zip"];
	return string;
}

@end
