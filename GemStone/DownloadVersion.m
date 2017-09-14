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

@interface DownloadVersion ()

@property 	NSFileHandle	*zipFile;

@end

@implementation DownloadVersion

@synthesize version = _version;

- (NSArray *)arguments;
{ 
	NSString *zippedFileName = [self.version zippedFileName];
	NSMutableString *http = [NSMutableString new];
	[http appendString:@kDownloadSite];
	[http appendString:zippedFileName];
	return [NSArray arrayWithObjects: @"--raw", http, nil];
}

- (void)cancel;
{
	[appController taskProgress:@"\n\nCancel request received.\nDeleting zip file . . .\n"];
	[self.zipFile closeFile];
	self.zipFile = nil;
	[fileManager removeItemAtPath:self.zipFilePath error:nil];
	_zipFilePath = nil;
	[super cancel];
	[appController taskProgress:@"Download cancel completed!\n"];
}

- (void)createZipFile;
{
	BOOL exists, isDirectory = NO, success;
	exists = [fileManager fileExistsAtPath:self.zipFilePath isDirectory:&isDirectory];
	if (exists) {
		if (isDirectory) {
			AppError(@"Please delete directory at: %@", self.zipFilePath);
		}
		NSError *error;
		success = [fileManager removeItemAtPath:self.zipFilePath error:&error];
		if (!success) {
			AppError(@"Unable to delete existing file: %@", [error localizedDescription]);
		}
	}
	success = [fileManager
			   createFileAtPath:self.zipFilePath
			   contents:[NSData new] 
			   attributes:nil];
	if (!success) {
		AppError(@"Unable to create file: %@", self.zipFilePath);
	}
	self.zipFile = [NSFileHandle fileHandleForWritingAtPath:self.zipFilePath];
	if (!self.zipFile) {
		AppError(@"Unable to open file: %@", self.zipFilePath);
	}
}

- (void)data:(NSData *)data;
{ 
	[self.zipFile writeData:data];
}

- (void)done;
{ 
	[self.zipFile closeFile];
	self.zipFile = nil;
	unsigned long long fileSize = [[fileManager
					 attributesOfItemAtPath:self.zipFilePath
					 error:nil] fileSize];
	if (!fileSize) {
		[fileManager removeItemAtPath:self.zipFilePath error:nil];
		_zipFilePath = nil;
		AppError(@"Empty zip file without an error!?");
	}
	[super done];
}

- (void)doneWithError:(int)statusCode;
{
	[self.zipFile closeFile];
	self.zipFile = nil;
	[fileManager removeItemAtPath:self.zipFilePath error:nil];
	_zipFilePath = nil;
	[super doneWithError:statusCode];
}

- (void)setVersion:(Version *)aVersion;
{
	self.version = aVersion;
	_zipFilePath = [NSMutableString stringWithFormat:@"%@/%@", basePath, [self.version zippedFileName]];
}

- (void)startTask;
{
	[self createZipFile];
	[super startTask];
}

- (Version *)version;
{
	return _version;
}

@end
