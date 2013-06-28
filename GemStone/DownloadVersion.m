//
//  DownloadVersion.m
//  GemStone
//
//  Created by James Foster on 5/9/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "DownloadVersion.h"
#import "Utilities.h"
#import "Version.h"

@implementation DownloadVersion

@synthesize version;
@synthesize zipFilePath;

- (NSArray *)arguments;
{ 
	NSString *zippedFileName = [version zippedFileName];
	NSMutableString *http = [NSMutableString new];
	[http appendString:@kDownloadSite];
	[http appendString:zippedFileName];
	return [NSArray arrayWithObjects: @"--raw", http, nil];
}

- (void)cancel;
{
	[appController taskProgress:@"\n\nCancel request received.\nDeleting zip file . . .\n"];
	[zipFile closeFile];
	zipFile = nil;
	[fileManager removeItemAtPath:zipFilePath error:nil];
	zipFilePath = nil;
	[super cancel];
	[appController taskProgress:@"Download cancel completed!\n"];
}

- (void)createZipFile;
{
	BOOL exists, isDirectory = NO, success;
	exists = [fileManager fileExistsAtPath:zipFilePath isDirectory:&isDirectory];
	if (exists) {
		if (isDirectory) {
			AppError(@"Please delete directory at: %@", zipFilePath);
		}
		NSError *error;
		success = [fileManager removeItemAtPath:zipFilePath error:&error];
		if (!success) {
			AppError(@"Unable to delete existing file: %@", [error localizedDescription]);
		}
	}
	success = [fileManager
			   createFileAtPath:zipFilePath 
			   contents:[NSData new] 
			   attributes:nil];
	if (!success) {
		AppError(@"Unable to create file: %@", zipFilePath);
	}
	zipFile = [NSFileHandle fileHandleForWritingAtPath:zipFilePath];
	if (!zipFile) {
		AppError(@"Unable to open file: %@", zipFilePath);
	}
}

- (void)data:(NSData *)data;
{ 
	[zipFile writeData:data];
}

- (void)done;
{ 
	[zipFile closeFile];
	zipFile = nil;
	unsigned long long fileSize = [[fileManager
					 attributesOfItemAtPath:zipFilePath 
					 error:nil] fileSize];
	if (!fileSize) {
		[fileManager removeItemAtPath:zipFilePath error:nil];
		zipFilePath = nil;
		AppError(@"Empty zip file without an error!?");
	}
	[super done];
}

- (void)doneWithError:(int)statusCode;
{
	[zipFile closeFile];
	zipFile = nil;
	[fileManager removeItemAtPath:zipFilePath error:nil];
	zipFilePath = nil;
	[super doneWithError:statusCode];
}

- (void)setVersion:(Version *)aVersion;
{
	version = aVersion;
	zipFilePath = [NSMutableString stringWithFormat:@"%@/%@", basePath, [version zippedFileName]];
}

- (void)startTask;
{
	[self createZipFile];
	[super startTask];
}

@end
