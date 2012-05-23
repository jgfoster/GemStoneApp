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

@dynamic isInstalledCode;
@dynamic name;
@dynamic date;
@dynamic indexInArray;

- (id)init;
{
	if (self = [super init]) {
		
	}
	return self;
}

- (BOOL)isActuallyInstalled;
{
	BOOL isDirectory;
	BOOL exists = [[NSFileManager defaultManager] 
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
	NSString *appSupDir = [[NSFileManager defaultManager] applicationSupportDirectory];
	NSMutableString *path = [NSMutableString stringWithString:appSupDir];
	[path appendString:@"/GemStone64Bit"];
	[path appendString:self.name];		//	use key accessor since value might not be faulted yet
	[path appendString:@"-i386.Darwin"];
	return path;
}

- (void)remove;
{
	NSError *error = nil;

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
			if (![fileManager setAttributes:attributes ofItemAtPath:path error:&error]) {
				[[NSNotificationCenter defaultCenter] postNotificationName:kRemoveVersionError object:error];
				return;
			}
		}
	}
	if ([[NSFileManager defaultManager] removeItemAtPath:[self productPath] error:&error]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kRemoveVersionDone object:self];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:kRemoveVersionError object:error];
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
