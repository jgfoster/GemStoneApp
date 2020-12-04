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

@property 	NSFileHandle	*file;

@end

@implementation DownloadVersion

@synthesize header = _header;
@synthesize path = _path;
@synthesize url = _url;

- (NSArray *)arguments;
{
	return [NSArray arrayWithObjects: @"--location", @"--raw", self.url, nil];
}

- (void)cancel {
	[appController taskProgress:@"\n\nCancel request received.\nDeleting file . . .\n"];
	[self.file closeFile];
	self.file = nil;
	[fileManager removeItemAtPath:self.path error:nil];
	self.path = nil;
	[super cancel];
	[appController taskProgress:@"Download cancel completed!\n"];
}

- (void)createFile {
	BOOL exists, isDirectory = NO, success;
	exists = [fileManager fileExistsAtPath:self.path isDirectory:&isDirectory];
	if (exists) {
		if (isDirectory) {
			AppError(@"Please delete directory at: %@", self.path);
		}
		NSError *error;
		success = [fileManager removeItemAtPath:self.path error:&error];
		if (!success) {
			AppError(@"Unable to delete existing file: %@", [error localizedDescription]);
		}
	}
	success = [fileManager
			   createFileAtPath:self.path
			   contents:[NSData new] 
			   attributes:nil];
	if (!success) {
		AppError(@"Unable to create file: %@", self.path);
	}
	self.file = [NSFileHandle fileHandleForWritingAtPath:self.path];
	if (!self.file) {
		AppError(@"Unable to open file: %@", self.path);
	}
}

- (void)data:(NSData *)data;
{ 
	[self.file writeData:data];
}

- (void)done;
{ 
	[self.file closeFile];
	self.file = nil;
	NSInteger actualSize = [[fileManager
					 attributesOfItemAtPath:self.path
					 error:nil] fileSize];
	NSInteger expectedSize = [self.header contentLength];
	if (actualSize != expectedSize) {
		[fileManager removeItemAtPath:self.path error:nil];
		self.path = nil;
		[appController taskProgress:[NSString stringWithFormat:@"Download expected %ld but got %ld bytes!", (long) expectedSize, (long) actualSize]];
		AppError(@"Download expected %ld but got %ld bytes!", (long) expectedSize, (long) actualSize);
	}
	[super done];
}

- (void)doneWithError:(int)statusCode {
	[self.file closeFile];
	self.file = nil;
	[fileManager removeItemAtPath:self.path error:nil];
	self.path = nil;
	[super doneWithError:statusCode];
}

- (void)startTask {
	[self createFile];
	[super startTask];
}

@end
