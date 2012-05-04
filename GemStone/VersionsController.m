//
//  VersionsController.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "VersionsController.h"

@implementation VersionsController

- (void)awakeFromNib;
{
	versions = [NSKeyedUnarchiver unarchiveObjectWithFile:[Versions archiveFilePath]];
	if (versions) {
		[versions updateIsInstalled];
	} else { 
		versions = [Versions new];
	}
	[self updateUI];
	
	//	set up notifications
	NSNotificationCenter *notifier = [NSNotificationCenter defaultCenter];
	[notifier removeObserver:self];
	[notifier addObserver:self selector:@selector(taskDone:) name:kVersionsTaskDone object:versions];
	[notifier addObserver:self selector:@selector(taskError:) name:kVersionsTaskError object:versions];
	[notifier addObserver:self selector:@selector(taskProgress:) name:kVersionsTaskProgress object:versions];
	[notifier addObserver:self selector:@selector(taskCancelled:) name:kTaskCancelNotificationName object:NSApp];
}

- (void)criticalAlert:(NSString *)string;
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert setMessageText:@"Task Failed"];
	[alert setInformativeText:string];
	[alert addButtonWithTitle:@"Dismiss"];
	[alert runModal];
}

- (void)downloadVersionAtRow:(NSInteger)rowIndex;
{
	NSString *string = [versions createZipFileForVersionAtRow:rowIndex];
	if (string) {
		[self criticalAlert:string];
		return;
	}
	//	start task
	[taskProgressController startTaskProgressSheetAndAllowCancel:YES];
	[versions downloadVersionAtRow:rowIndex];
}

- (IBAction)importVersion:(id)sender
{
	//	get path to zip file
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setDelegate:self];
    if ([op runModal] != NSOKButton) return;

	//	start task
	[taskProgressController startTaskProgressSheetAndAllowCancel:NO];
	[versions import:[[op URLs] objectAtIndex:0]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [versions countOfVersions];
}

//	NSOpenPanelDelegate method for file import
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

- (void)removeVersionAtRow:(NSInteger)rowIndex;
{
	NSString *string = [versions removeVersionAtRow:rowIndex];
	if (!string) return;
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert setMessageText:@"Removal Failed!"];
	[alert setInformativeText:string];
	[alert addButtonWithTitle:@"Dismiss"];
	[alert runModal];
}

// get table cell
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [versions getRow:rowIndex column:[aTableColumn identifier]];
}

// set table cell
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	SEL selector = NSSelectorFromString([aTableColumn identifier]);
	if (selector != @selector(isInstalledNumber)) {
		NSLog(@"Should not modify column %@", [aTableColumn identifier]);
		return;
	}
	if ([anObject boolValue]) {
		[self downloadVersionAtRow:rowIndex];
	} else {
		[self removeVersionAtRow:rowIndex];
	}
}

// table sorting
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	[versions sortUsingDescriptors:[tableView sortDescriptors]];
	[self updateUI];
}

- (void)taskDone:(NSNotification*)notification;
{
	[taskProgressController taskFinished];
	[self updateUI];
}

- (void)taskError:(NSNotification*)notification;
{
	[self criticalAlert:[[notification userInfo] objectForKey:@"string"]];
	[self taskDone:nil];
}

- (void)taskProgress:(NSNotification*)notification;
{
	[taskProgressController taskProgress:[[notification userInfo] objectForKey:@"string"]];
}

- (void)updateUI
{
	[versions save];
	[dateField setStringValue:[versions updateDateString]];
	[versionsTable reloadData];
}

- (IBAction)updateVersions:(id)sender;
{
	//	start task
	[taskProgressController startTaskProgressSheetAndAllowCancel:YES];
	[versions update];
}

- (void)taskCancelled:(NSNotification*)notification;
{
	[versions terminateTask];
	[self taskDone:notification];
}

@end
