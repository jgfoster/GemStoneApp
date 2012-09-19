//
//  DownloadVersion.m
//  GemStone
//
//  Created by James Foster on 5/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
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
	[http appendString:@"http://seaside.gemstone.com/downloads/i386.Darwin/"];
	[http appendString:zippedFileName];
	return [NSArray arrayWithObjects: @"--raw", http, nil];
}

- (void)cancelTask;
{
	[zipFile closeFile];
	zipFile = nil;
	[fileManager removeItemAtPath:zipFilePath error:nil];
	zipFilePath = nil;
	[super cancelTask];
}

- (NSString *)createZipFile;
{
	BOOL exists, isDirectory = NO, success;
	exists = [fileManager fileExistsAtPath:zipFilePath isDirectory:&isDirectory];
	if (exists) {
		if (isDirectory) {
			return [@"Please delete directory at:" stringByAppendingString:zipFilePath];
		}
		NSError *error;
		success = [fileManager removeItemAtPath:zipFilePath error:&error];
		if (!success) {
			return [@"Unable to delete existing file: " stringByAppendingString:[error localizedDescription]];
		}
	}
	success = [fileManager
			   createFileAtPath:zipFilePath 
			   contents:[NSData new] 
			   attributes:nil];
	if (!success) {
		return [@"Unable to create file: " stringByAppendingString:zipFilePath];
	}
	zipFile = [NSFileHandle fileHandleForWritingAtPath:zipFilePath];
	if (!zipFile) {
		return [@"Unable to open file: " stringByAppendingString:zipFilePath];
	}
	return nil;
}

- (void)data:(NSData *)data;
{ 
	[zipFile writeData:data];
}

- (void)done;
{ 
	[zipFile closeFile];
	zipFile = nil;
	int fileSize = [[fileManager
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

- (void)start;
{
	[self verifyNoTask];
	NSString *errorString = [self createZipFile];
	if (errorString) {
		AppError(@"%@", errorString);
	}
	[super start];
}

@end
