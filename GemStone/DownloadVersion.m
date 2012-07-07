//
//  DownloadVersion.m
//  GemStone
//
//  Created by James Foster on 5/9/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "AppController.h"
#import "DownloadVersion.h"
#import "Version.h"

@implementation DownloadVersion

@synthesize version;
@synthesize zipFilePath;

- (NSArray *)arguments;
{ 
	NSString *zippedFileName = [version zippedFileName];
	NSMutableString *http = [NSMutableString new];
	[http appendString:@"http://seaside.gemstone.comm/downloads/i386.Darwin/"];
	[http appendString:zippedFileName];
	return [NSArray arrayWithObjects: @"--raw", http, nil];
}

- (void)cancelTask;
{
	[[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
	[super cancelTask];
}

- (NSString *)createZipFile;
{
	NSString *zippedFileName = [version zippedFileName];
	zipFilePath = [NSMutableString stringWithFormat:@"%@/%@", [[NSApp delegate] basePath], zippedFileName];
	BOOL exists, isDirectory = NO, success;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:zipFilePath isDirectory:&isDirectory];
	if (exists) {
		if (isDirectory) {
			return [@"Please delete directory at:" stringByAppendingString:zipFilePath];
		}
		NSError *error;
		success = [[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:&error];
		if (!success) {
			return [@"Unable to delete existing file: " stringByAppendingString:[error localizedDescription]];
		}
	}
	success = [[NSFileManager defaultManager] 
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
	if (!task) return;		// task cancelled!
	task = nil;
	int fileSize = [[[NSFileManager defaultManager] 
					 attributesOfItemAtPath:zipFilePath 
					 error:nil] fileSize];
	if (fileSize) {
		[self notifyDone];
		zipFilePath = nil;
	} else {
		[[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
		zipFilePath = nil;
		NSString *message = @"'RETR 550' means that this version of GemStone/S 64 Bit is not available for the Macintosh.";
		NSDictionary *userInfo = [NSDictionary
								  dictionaryWithObject:message
								  forKey:@"string"];
		NSNotification *outNotification = [NSNotification
										   notificationWithName:kTaskError 
										   object:self
										   userInfo:userInfo];
		[[NSNotificationCenter defaultCenter] postNotification:outNotification];
	}
}

- (void)start;
{
	[self verifyNoTask];
	NSString *errorString = [self createZipFile];
	if (errorString) {
		NSLog(@"%@", errorString);
		return;
	}
	[super start];
}

@end
