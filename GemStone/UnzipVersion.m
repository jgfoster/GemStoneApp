//
//  UnzipVersion.m
//  GemStone
//
//  Created by James Foster on 9/19/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "AppController.h"
#import "UnzipVersion.h"
#import "Utilities.h"

@implementation UnzipVersion

@synthesize zipFilePath;

- (NSArray *)arguments;
{
	if (!zipFilePath) AppError(@"Zip file path must be provided!");	
	return [NSArray arrayWithObjects:
			zipFilePath, 
			@"-d",
			basePath,
			nil];
}

- (void)cancel;
{
	[super cancel];
	if (!directoryContents) return;
	[appController taskProgress:@"\n\nCancel request received.\nDeleting unzipped items . . .\n"];
	NSError *error = nil;
	NSArray *currentList = [fileManager contentsOfDirectoryAtPath:basePath error:&error];
	if (!currentList) {
		AppError(@"Unable to obtain contents of directory at %@", basePath);
	}
	for (id current in currentList) {
		Boolean	flag = NO;
		for (id prior in directoryContents) {
			flag = flag || [current isEqualToString:prior];
		}
		if (!flag) {
			NSString *path = [[basePath stringByAppendingString:@"/"] stringByAppendingString:current];
			[Version removeVersionAtPath:path];
		}
	}
	if ([zipFilePath hasPrefix:basePath]) {
		[fileManager removeItemAtPath:zipFilePath error:nil];
	}
}

- (void)dataString:(NSString *)aString;
{
	[self progress:aString];
}

- (void)done;
{
	if ([zipFilePath hasPrefix:basePath]) {
		[fileManager removeItemAtPath:zipFilePath error:nil];
	}
	[super done];
}

- (void)errorOutputString:(NSString *)aString;
{
	NSLog(@"%@", aString);
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Unzip error!"];
	[alert setInformativeText:aString];
	[alert addButtonWithTitle:@"Dismiss"];
	[alert runModal];
	[self cancel];
}

- (NSString *)launchPath;
{
	return @"/usr/bin/unzip";
}

- (void)main;
{
	NSError *error = nil;
	directoryContents = [fileManager contentsOfDirectoryAtPath:basePath error:&error];
	if (!directoryContents) {
		AppError(@"Unable to obtain contents of %@", basePath);
	}
    [appController taskStart:@"Starting import of zip file . . .\n"];
	[super main];
}

//	NSOpenPanelDelegate method for file import
- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url;
{
	NSString *path = [url path];
	BOOL isDirectory;
	[fileManager fileExistsAtPath:path isDirectory:&isDirectory];
	if (isDirectory) {
		return ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:path];
	}
	NSRange range = [path rangeOfString:@"/GemStone64Bit"];
	if (range.location == NSNotFound) return NO;
	range = [path rangeOfString:@"-i386.Darwin.zip"];
	return range.location + range.length == [path length];
}

- (void)unzip;
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    [op setResolvesAliases:YES];
    [op setAllowsMultipleSelection:NO];
    [op setTitle:@"Add New Version"];
    [op setPrompt:@"Unzip"];
    [op setMessage:@"Select GemStone/S product:"];
    [op setCanSelectHiddenExtension:YES];
    [op setAllowedFileTypes:[NSArray arrayWithObjects:@"zip",@"ZIP", nil]];
    [op setAllowsMultipleSelection:NO];
    [op setTreatsFilePackagesAsDirectories:NO];
    [op beginSheetModalForWindow:[NSApp mainWindow]
               completionHandler:^(NSInteger result) {
                   if (result != NSFileHandlingPanelOKButton) return;
                   __block id me = self;
                   zipFilePath = [[[op URLs] objectAtIndex:0] path];
                   [self setCompletionBlock:^(){
                       [appController performSelectorOnMainThread:@selector(versionUnzipDone:)
                                                       withObject:me
                                                    waitUntilDone:NO];
                   }];
                   [appController addOperation:self];
               }];
}

@end
