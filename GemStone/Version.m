//
//  Version.m
//  GemStone
//
//  Created by James Foster on 4/22/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "DownloadVersion.h"
#import "UnzipVersion.h"
#import "Utilities.h"
#import "Version.h"

@implementation Version

@dynamic isInstalledCode;
@dynamic name;
@dynamic date;
@dynamic indexInArray;

+ (void)removeVersionAtPath:(NSString *)productPath;
{
	NSError *error = nil;
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:productPath];
	NSString *file;
	NSDictionary *attributes = [NSDictionary 
								dictionaryWithObject:[NSNumber numberWithUnsignedLong:0777U] 
								forKey:NSFilePosixPermissions];
	[appController taskProgress:@"Update permissions to allow delete . . .\n"];
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
	[appController taskProgress:@"Start delete . . .\n"];
	if (![fileManager removeItemAtPath:productPath error:&error]) {
		AppError(@"Unable to remove %@ because %@", productPath, [error description]);
	}
	[appController taskProgress:@"Finish delete . . .\n"];
}

- (void)download;
{
	[appController taskStart:[NSString stringWithFormat:@"Downloading %@ . . .\n", name]];
	DownloadVersion *download = [DownloadVersion new];
	[download setVersion:self];
	
	UnzipVersion *unzip = [UnzipVersion new];
	[unzip setZipFilePath: [download zipFilePath]];
	[unzip addDependency:download];
	__block Task *blockTask = unzip;
	[unzip setCompletionBlock:^(){
		[appController performSelectorOnMainThread:@selector(versionUnzipDone:) 
										withObject:blockTask
									 waitUntilDone:NO];
	}];
	[appController addOperation:download];
	[appController addOperation:unzip];
}

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
	[appController taskStart:@"Removing GemStone/S 64 Bit product tree . . .\n"];
	[Version removeVersionAtPath:[self productPath]];
	[appController removeVersionDone];
}

- (void)setIsInstalledCode:(NSNumber *)aNumber;
{
	if (isInstalledCode == aNumber) return;
	if ([self isActuallyInstalled] == [aNumber boolValue]) {
		isInstalledCode = aNumber;
		return;
	}
	if ([aNumber boolValue]) {
		[self download];
	} else {
		[self remove];
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
