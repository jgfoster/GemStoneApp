//
//  Version.m
//  GemStone
//
//  Created by James Foster on 4/22/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "DownloadHeader.h"
#import "DownloadVersion.h"
#import "MountDMG.h"
#import "UnzipVersion.h"
#import "Utilities.h"
#import "Version.h"

@interface Version ()

@property 	NSString 	*path;
@property 	NSString 	*url;

@end

@implementation Version

@dynamic date;
@dynamic indexInArray;
@dynamic isInstalledCode;
@dynamic name;
@synthesize path = _path;
@synthesize url = _url;

+ (void)removeVersionAtPath:(NSString *)productPath {
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

- (void)dmgHeader:(DownloadHeader*)dmgHeader {
	if ([dmgHeader resultCode] != 200) {
		[appController taskProgress:@"\nLooking for ZIP file . . .\n"];
		DownloadHeader *zipHeader = [DownloadHeader new];
		[zipHeader setUrl:[NSString stringWithFormat:@"%@%@", self.url, @"zip"]];
		__block DownloadHeader *headerTask = zipHeader;		//	blocks get a COPY of referenced objects unless explicitly shared
		[zipHeader setCompletionBlock:^(){
			[self zipHeader:headerTask];
			headerTask = nil;		//	to break retain cycle
		}];
		[appController addOperation:zipHeader];
		return;
	}
	NSInteger contentLength = [dmgHeader contentLength];
	[appController taskProgress:[NSString stringWithFormat:@"\nFound DMG file with %ld bytes\n", contentLength]];
	
	DownloadVersion *download = [DownloadVersion new];
	[download setPath:[NSString stringWithFormat:@"%@%@", self.path, @"dmg"]];
	[download setUrl:[NSString stringWithFormat:@"%@%@", self.url, @"dmg"]];
	[download setHeader:dmgHeader];

	MountDMG *mountDMG = [MountDMG new];
	[mountDMG setFilePath: [download path]];
	[mountDMG addDependency:download];

	[appController addOperation:download];
	[appController addOperation:mountDMG];
}

- (void)download {
	NSString *fileName;
	[appController taskStart:[NSString stringWithFormat:@"Looking for DMG for %@ . . .\n", self.name]];
	fileName = [NSString stringWithFormat:@"%@%@%@", @"GemStone64Bit", self.name, @"-i386.Darwin."];
	self.url = [NSString stringWithFormat:@"%@%@", @kDownloadSite, fileName];
	self.path = [NSString stringWithFormat:@"%@/%@", basePath, fileName];
	
	DownloadHeader *dmgHeader = [DownloadHeader new];
	[dmgHeader setUrl:[NSString stringWithFormat:@"%@%@", self.url, @"dmg"]];
	__block DownloadHeader *headerTask = dmgHeader;		//	blocks get a COPY of referenced objects unless explicitly shared
	[dmgHeader setCompletionBlock:^(){
		[self dmgHeader:headerTask];
		headerTask = nil;		//	to break retain cycle
	}];
	[appController addOperation:dmgHeader];
}

- (BOOL)isActuallyInstalled {
	BOOL isDirectory;
	BOOL exists = [fileManager
				   fileExistsAtPath:[self productPath] 
				   isDirectory:&isDirectory];
	return exists && isDirectory;
}

- (BOOL)isInstalled {
	return [self.isInstalledCode boolValue];
}

- (NSString *)productPath {
	return [NSString stringWithFormat:@"%@/GemStone64Bit%@-i386.Darwin", basePath, self.name];
}

- (void)remove {
	if ([appController databaseExistsForVersion:self]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Database(s) exist for Version!"];
		[alert setInformativeText:@"Please delete databases for this version first!"];
		[alert addButtonWithTitle:@"Dismiss"];
		[alert runModal];
	} else {
		[appController taskStart:@"Removing GemStone/S 64 Bit product tree . . .\n"];
		[Version removeVersionAtPath:[self productPath]];		
	}
	[appController removeVersionDone];
}

- (void)setIsInstalledCode:(NSNumber *)aNumber {
	if (self.isInstalledCode == aNumber) return;
	if ([self isActuallyInstalled] == [aNumber boolValue]) {
		_isInstalledCode = aNumber;
		return;
	}
	if ([aNumber boolValue]) {
		[self download];
	} else {
		[self remove];
	}
}

- (void)updateIsInstalled {
	NSNumber *code = [NSNumber numberWithBool:[self isActuallyInstalled]];
	if (code != self.isInstalledCode) {
		_isInstalledCode = code;
	}
}

- (void)zipHeader:(DownloadHeader*)zipHeader;
{
	if ([zipHeader resultCode] != 200) {
		[appController taskProgress:[NSString stringWithFormat:@"\nServer returned error code %ld\n", [zipHeader resultCode]]];
		[appController taskFinishedAfterDelay];
		return;
	}
	NSInteger contentLength = [zipHeader contentLength];
	[appController taskProgress:[NSString stringWithFormat:@"\nFound ZIP file with %ld bytes\n", contentLength]];
	
	DownloadVersion *download = [DownloadVersion new];
	[download setPath:[NSString stringWithFormat:@"%@%@", self.path, @"zip"]];
	[download setUrl:[NSString stringWithFormat:@"%@%@", self.url, @"zip"]];
	[download setHeader:zipHeader];

	UnzipVersion *unzip = [UnzipVersion new];
	[unzip setFilePath: [download path]];
	[unzip addDependency:download];
	__block Task *blockTask = unzip;		//	blocks get a COPY of referenced objects unless explicitly shared
	[unzip setCompletionBlock:^(){
		[appController performSelectorOnMainThread:@selector(versionInstallDone:)
										withObject:blockTask
									 waitUntilDone:NO];
		blockTask = nil;		//	to break retain cycle
	}];
	[appController addOperation:download];
	[appController addOperation:unzip];
}

@end
