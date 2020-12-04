//
//  InstallVersion.m
//  GemStone
//
//  Created by James Foster on 12/3/20.
//  Copyright © 2020 GemTalk Systems LLC. All rights reserved.
//

#import "AppController.h"
#import "InstallVersion.h"
#import "Utilities.h"

@interface InstallVersion ()

@property 	NSArray		*directoryContents;

@end

@implementation InstallVersion

- (void)cancel {
	[super cancel];
	if (!self.directoryContents) return;
	[appController taskProgress:@"\n\nCancel request received.\nDeleting items . . .\n"];
	NSError *error = nil;
	NSArray *currentList = [fileManager contentsOfDirectoryAtPath:basePath error:&error];
	if (!currentList) {
		AppError(@"Unable to obtain contents of directory at %@", basePath);
	}
	for (id current in currentList) {
		Boolean	flag = NO;
		for (id prior in self.directoryContents) {
			flag = flag || [current isEqualToString:prior];
		}
		if (!flag) {
			NSString *path = [[basePath stringByAppendingString:@"/"] stringByAppendingString:current];
			[Version removeVersionAtPath:path];
		}
	}
	if ([self.filePath hasPrefix:basePath]) {
		[fileManager removeItemAtPath:self.filePath error:nil];
	}
}

- (void)install {
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseFiles:YES];
	[op setCanChooseDirectories:NO];
	[op setResolvesAliases:YES];
	[op setAllowsMultipleSelection:NO];
	[op setTitle:@"Add New Version"];
	[op setPrompt:@"Install"];
	[op setMessage:@"Select GemStone/S product:"];
	[op setCanSelectHiddenExtension:YES];
	[op setAllowedFileTypes:[NSArray arrayWithObjects:@"dmg",@"DMG",@"zip",@"ZIP", nil]];
	[op setAllowsMultipleSelection:NO];
	[op setTreatsFilePackagesAsDirectories:NO];
	[op beginSheetModalForWindow:[NSApp mainWindow]
			   completionHandler:^(NSInteger result) {
				   [op orderOut:nil];
				   if (result != NSModalResponseOK) return;
				   __block id me = self;		//	blocks get a COPY of referenced objects unless explicitly shared
				   self.filePath = [[[op URLs] objectAtIndex:0] path];
				   [self setCompletionBlock:^(){
					   [appController performSelectorOnMainThread:@selector(versionInstallDone:)
													   withObject:me
													waitUntilDone:NO];
					   me = nil;	// to break retain cycle
				   }];
				   [appController addOperation:me];
			   }];
}

- (void)dataString:(NSString *)aString {
	[self progress:aString];
}

- (void)done {
	[super done];
}

- (void)errorOutputString:(NSString *)aString {
	[self performSelectorOnMainThread:@selector(errorOutputStringA:)
						   withObject:aString
						waitUntilDone:YES];
}

- (void)errorOutputStringA:(NSString *)aString {
	NSLog(@"%@", aString);
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Install error!"];
	[alert setInformativeText:aString];
	[alert addButtonWithTitle:@"Dismiss"];
	[alert runModal];
	[self cancel];
}

- (void)main {
	for (id dependency in [self dependencies]) {
		if ([dependency isCancelled]) return;
	}
	NSError *error = nil;
	self.directoryContents = [fileManager contentsOfDirectoryAtPath:basePath error:&error];
	if (!self.directoryContents) {
		AppError(@"Unable to obtain contents of %@", basePath);
	}
	[appController taskStart:@"Starting install . . .\n"];
	[super main];
}

//	NSOpenPanelDelegate method for file import
- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
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

@end
