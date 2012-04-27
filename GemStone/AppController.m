//
//  AppController.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "AppController.h"
#import "VersionsController.h"

@interface AppController ()
@end

@implementation AppController

@synthesize versions;

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename;
{
	NSLog(@"application:openFile: %@", filename);
	return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
	BOOL isCurrent = [helper isCurrent];
	[helperToolMessage setHidden:!isCurrent];
	[authenticateButton setEnabled:!isCurrent];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	return NO;
}

- (void)cancelMethod:(SEL)selector;
{
	cancelMethod = selector;
}

- (IBAction)cancelTask:(id)sender
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	[self performSelector:cancelMethod];
#pragma clang diagnostic pop
}

- (void)cancelInstallVersion
{
	[versions cancelTask];
}

- (void)cancelUpdateVersions
{
	[versions cancelTask];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	usleep(500000);
	[sheet orderOut:self];
}


- (IBAction)importVersion:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setDelegate:self];
    if ([op runModal] == NSOKButton) {
		[self startTaskProgressSheet];
		[versions import:[[op URLs] objectAtIndex:0]];
	}
}

- (IBAction)installHelperTool:(id)sender
{
	if ([helper install]) {
		[authenticateButton setEnabled:NO];
		[helperToolMessage setHidden:NO];
	}
}

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url;
{
	NSString *path = [url path];
	BOOL isDirectory;
	[[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
	if (isDirectory) {
		return ![[NSWorkspace sharedWorkspace] isFilePackageAtPath:path];
	}
	NSRange range = [path rangeOfString:@"/GemStone64Bit"];
	if (range.location == NSNotFound) return NO;
	range = [path rangeOfString:@"-i386.Darwin.zip"];
	return range.location + range.length == [path length];
}

- (void)startTaskProgressSheet;
{
    [NSApp beginSheet:taskProgressPanel
       modalForWindow:[NSApp mainWindow]
        modalDelegate:self
       didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
          contextInfo:nil];
	[taskProgressText setFont:[NSFont fontWithName:@"Monaco" size:9]];
	[taskProgressIndicator startAnimation:self];
	[taskCancelButton setEnabled:cancelMethod != nil];
}

- (void)taskFinished
{
	[taskProgressIndicator stopAnimation:self];
	[taskProgressText setString:[NSMutableString new]];
	[NSApp endSheet:taskProgressPanel];
	cancelMethod = nil;
}

- (void)taskProgress:(NSString *)string
{
	[taskProgressText insertText:string];
}

- (IBAction)updateVersions:(id)sender
{
	cancelMethod = @selector(cancelUpdateVersions);
	[self startTaskProgressSheet];
	[versions update];
}

@end
