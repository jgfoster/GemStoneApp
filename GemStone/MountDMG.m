//
//  MountDMG.m
//  GemStone
//
//  Created by James Foster on 12/3/20.
//  Copyright © 2020 GemTalk Systems LLC. All rights reserved.
//

#import "AppController.h"
#import "MountDMG.h"
#import "UnmountDMG.h"
#import "Utilities.h"

@implementation MountDMG

- (NSArray *)arguments {
	if (!self.filePath) AppError(@"DMG file path must be provided!");
	return [NSArray arrayWithObjects:
			@"mount",
			self.filePath,
			nil];
}

- (void)cancel {
	[super cancel];
}

- (void)done {
	[appController taskProgress:@"\nDMG mounted. Starting file copy . . .\n"];
	NSURL *directoryURL = [NSURL fileURLWithPath:@"/Volumes/installGemStone/" isDirectory:YES];
	NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtURL:directoryURL
											 includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, NSURLIsDirectoryKey,nil]
																options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
														   errorHandler:nil];
	NSURL *srcURL;
	for (NSURL *theURL in dirEnumerator) {
		srcURL = theURL;
		break;
	}
	NSString *fileName;
	[srcURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
	NSURL *dstURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", basePath, fileName] isDirectory:YES];
	NSError *error;
	BOOL flag = [fileManager copyItemAtURL:srcURL
									 toURL:dstURL
									 error:&error];
	if (!flag) {
		[appController taskProgress:[NSString stringWithFormat:@"Copy error: %@", error]];
		NSLog(@"Copy error: %@", error);
		[self cancel];
		return;
	}
	if ([self.filePath hasPrefix:basePath]) {
		[fileManager removeItemAtPath:self.filePath error:nil];
	}
	[appController taskProgress:@"Copy successful. Unmounting DMG . . .\n"];
	UnmountDMG *unmountTask =[UnmountDMG new];
	[appController addOperation:unmountTask];
	__block Task *blockTask = unmountTask;		//	blocks get a COPY of referenced objects unless explicitly shared
	[unmountTask setCompletionBlock:^(){
		[appController performSelectorOnMainThread:@selector(versionInstallDone:)
										withObject:blockTask
									 waitUntilDone:NO];
		blockTask = nil;		//	to break retain cycle
	}];
	[super done];
}

- (NSString *)launchPath {
	return @"/usr/bin/hdiutil";
}

@end
