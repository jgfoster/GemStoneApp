//
//  AppController.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <ExceptionHandling/NSExceptionHandler.h>

#import "AppController.h"
#import "Database.h"
#import "DownloadVersion.h"
#import "DownloadVersionList.h"
#import "ImportZippedVersion.h"
#import "LogFile.h"
#import "Login.h"
#import "StartNetLDI.h"
#import "StartStone.h"
#import "Statmonitor.h"
#import "StopNetLDI.h"
#import "StopStone.h"
#import "Utilities.h"
#import "Version.h"

@implementation AppController

@synthesize setup;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
	helper = [Helper new];
	BOOL isCurrent = [helper isCurrent];
	[helperToolMessage setHidden:!isCurrent];
	[authenticateButton setEnabled:!isCurrent];
	[removeButton setEnabled:isCurrent];
	
	[self loadSetup];
	[self loadRequest:@"Database" toController:databaseListController];
	[self loadRequest:@"Login" toController:loginListController];
	[self loadRequest:@"Version" toController:versionListController];
	[self refreshInstalledVersionsList];
	
#define NotifyMe(aString, aSymbol) \
		[notificationCenter addObserver:self selector:@selector(aSymbol:) name:aString object:nil]
	NotifyMe(kTaskError,				taskError);
	NotifyMe(kTaskProgress,				taskProgress);
	NotifyMe(kDownloadRequest,			downloadRequest);
	NotifyMe(kRemoveRequest,			removeRequest);
	NotifyMe(kDatabaseStartRequest,		databaseStartRequest);
	NotifyMe(kDatabaseStopRequest,		databaseStopRequest);
	NotifyMe(kDababaseInfoChanged,		updateDatabaseList);
	
	[databaseListController addObserver:self
							 forKeyPath:@"selection"
								options:(NSKeyValueObservingOptionNew)
								context:NULL];

	[taskProgressText setFont:[NSFont fontWithName:@"Monaco" size:9]];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
{
	for (id database in [databaseListController arrangedObjects]) {
		if ([database isRunning]) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"Database(s) are running!"];
			[alert setInformativeText:@"Please stop all databases before quitting application!"];
			[alert addButtonWithTitle:@"Dismiss"];
			[alert runModal];
			return NSTerminateCancel;
		}
	}
	return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification;
{
	NSArray *list;
	list = [versionListController arrangedObjects];
	for (NSInteger i = 0; i < [list count]; ++i) {
		Version *version = [list objectAtIndex:i];
		if (version.indexInArray != [NSNumber numberWithInt:i]) {
			version.indexInArray = [NSNumber numberWithInt:i];
		}
	}
	list = [loginListController arrangedObjects];
	for (NSInteger i = 0; i < [list count]; ++i) {
		Login *login = [list objectAtIndex:i];
		if (login.indexInArray != [NSNumber numberWithInt:i]) {
			login.indexInArray = [NSNumber numberWithInt:i];
		}
	}
	list = [databaseListController arrangedObjects];
	for (NSInteger i = 0; i < [list count]; ++i) {
		Database *database = [list objectAtIndex:i];
		if (database.indexInArray != [NSNumber numberWithInt:i]) {
			database.indexInArray = [NSNumber numberWithInt:i];
		}
	}
	NSManagedObjectContext *moc = [self managedObjectContext];
	if (![moc hasChanges]) {
		return;
	}
	NSError *error = nil;
	if (![moc save:&error]) {
		AppError(@"Data save failed\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
	}
}

- (IBAction)cancelTask:(id)sender
{
	if (!task) return;
	[task cancelTask];
	[self taskFinishedAfterDelay:0];
}

- (void)criticalAlert:(NSString *)textString details:(NSString *)detailsString;
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert setMessageText:textString];
	[alert setInformativeText:detailsString];
	[alert addButtonWithTitle:@"Dismiss"];
	[alert runModal];
}

- (void)databaseStartNetLdiDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:task];
	Database *database = [(DatabaseTask *) task database];
	Statmonitor *monitor = [Statmonitor new];
	[monitor setDatabase:database];
	[monitor start];
	NSString *key = [[database identifier] stringValue];
	[statmonitors setValue:monitor forKey:key];
	[self updateDatabaseList:nil];
	[self taskFinishedAfterDelay:0.5];
	[self performSelector:@selector(updateDatabaseList:) withObject:nil afterDelay:1.0];
}

- (void)databaseStartStoneDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:task];
	Database *database = [(DatabaseTask *) task database];
	StartNetLDI *startNetLdiTask = [StartNetLDI new];
	task = startNetLdiTask;
	[startNetLdiTask setDatabase:database];
	[notificationCenter
	 addObserver:self 
	 selector:@selector(databaseStartNetLdiDone:) 
	 name:kTaskDone 
	 object:task];
	[task start];
}

- (void)databaseStartRequest:(NSNotification *)notification;
{
	[self verifyNoTask];
	StartStone *myTask = [StartStone new];
	task = myTask;
	[myTask setDatabase:[notification object]];
	[notificationCenter
	 addObserver:self 
	 selector:@selector(databaseStartStoneDone:) 
	 name:kTaskDone 
	 object:task];
	[self startTaskProgressSheetAndAllowCancel:YES];
	[task start];
}

- (void)databaseStopNetLdiDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:task];
	Database *database = [(DatabaseTask *) task database];
	[statmonitors setValue:nil forKey:[[database identifier] stringValue]];
	[self updateDatabaseList:nil];
	[self taskFinishedAfterDelay:0.5];
}

- (void)databaseStopStoneDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:task];
	Database *database = [(DatabaseTask *) task database];
	[database archiveCurrentLogFiles];
	[database archiveCurrentTransactionLogs];
	StopNetLDI *stopNetLdiTask = [StopNetLDI new];
	task = stopNetLdiTask;
	[stopNetLdiTask setDatabase:database];
	[notificationCenter
	 addObserver:self 
	 selector:@selector(databaseStopNetLdiDone:) 
	 name:kTaskDone 
	 object:task];
	[task start];
}

- (void)databaseStopRequest:(NSNotification *)notification;
{
	[self verifyNoTask];
	StopStone *myTask = [StopStone new];
	task = myTask;
	[myTask setDatabase:[notification object]];
	[notificationCenter
	 addObserver:self 
	 selector:@selector(databaseStopStoneDone:) 
	 name:kTaskDone 
	 object:task];
	[self startTaskProgressSheetAndAllowCancel:YES];
	[task start];
	[taskProgressText insertText:@"Initiating database shutdown . . .\n\n"];
}

- (IBAction)defaultLogin:(id)sender;
{
	Database *database = [[databaseListController selectedObjects] objectAtIndex:0];
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObjectModel *managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
	NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Login"];
	Login *login = [[Login alloc]
					initWithEntity:entity
					insertIntoManagedObjectContext:moc];
	[login initializeForDatabase:database];
	NSLog(@"login = %@", login);
}

- (void)downloadDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:task];
	task = nil;	
	[taskCancelButton setEnabled:NO];
	[self unzipPath:[[notification object] zipFilePath]];
}

- (void)downloadRequest:(NSNotification *)notification;
{
	[self verifyNoTask];
	DownloadVersion *myTask = [DownloadVersion new];
	task = myTask;
	[myTask setVersion:[notification object]];
	[notificationCenter
	 addObserver:self 
	 selector:@selector(downloadDone:) 
	 name:kTaskDone 
	 object:task];
	[self startTaskProgressSheetAndAllowCancel:YES];
	[task start];
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(unsigned int)aMask;
{
	NSString *string = [NSString stringWithFormat:@"%@\n\nSee Console for details.", [exception reason]];
	[self criticalAlert:@"Internal Application Error!" details:string];
	[self taskFinishedAfterDelay:0];
	return YES;
}

- (id)init;
{
	if (self = [super init]) {
		[[Utilities new] setupGlobals];
		[self setupExceptionHandler];
		statmonitors = [NSMutableDictionary new];
	}
	return self;
}

- (IBAction)installHelperTool:(id)sender
{
	[helper install];
	[authenticateButton setEnabled:NO];
	[helperToolMessage setHidden:NO];
	[removeButton setEnabled:YES];
}

- (void)loadRequest:(NSString *)requestName toController:(NSArrayController *)controller;
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSError *error = nil;
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:requestName];
	NSArray *list = [moc executeFetchRequest:request error:&error];
	if (!list) {
        AppError(@"Data load failed\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
		list = [NSArray new];
	}
	NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"indexInArray" ascending:YES];
	NSArray *descriptors = [NSArray arrayWithObjects:descriptor, nil];
	NSArray *sortedArray = [list sortedArrayUsingDescriptors:descriptors];
	[controller setSelectsInsertedObjects:NO];
	[controller addObjects:sortedArray];
	[controller setSelectsInsertedObjects:YES];
}

- (void)loadSetup;
{
	NSArrayController *setupController = [NSArrayController new];
	[self loadRequest:@"Setup" toController:setupController];
	int count = [[setupController arrangedObjects] count];
	if (count) {
		setup = [[setupController arrangedObjects] objectAtIndex:0];
	} else {
		NSManagedObjectContext *moc = [self managedObjectContext];
		NSManagedObjectModel *managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
		NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Setup"];
		setup = [[Setup alloc]
				 initWithEntity:entity 
				 insertIntoManagedObjectContext:moc];
		setup.lastDatabaseIdentifier = [NSNumber numberWithInt:0];
	}
}

- (NSManagedObjectContext *)managedObjectContext;
{
    static NSManagedObjectContext *moc = nil;
    if (moc != nil) {
        return moc;
    }
	
    moc = [[NSManagedObjectContext alloc] init];

	NSPersistentStoreCoordinator *coordinator =
	[[NSPersistentStoreCoordinator alloc]
	 initWithManagedObjectModel: [NSManagedObjectModel mergedModelFromBundles:nil]];
    [moc setPersistentStoreCoordinator: coordinator];
	
    NSError *error = nil;
    NSURL *url = [NSURL 
				  fileURLWithPath:[basePath stringByAppendingString:@"/data.binary"] 
				  isDirectory:NO];
	
    NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:NSBinaryStoreType
															configuration:nil
																	  URL:url
																  options:nil
																	error:&error];
    if (newStore == nil) {
        AppError(@"Store Configuration Failure\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
    }
	return moc;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if (object == databaseListController) {
		NSArray *list = [databaseListController selectedObjects];
		Database *database = nil;
		if (0 < [list count]) {
			database = [list objectAtIndex:0];
		}
		[self selectedDatabase:database];
		return;
	}
	NSLog(@"keyPath = %@; object = %@; change = %@; context = %@", keyPath, object, change, context);
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

- (IBAction)removeDatabase:(id)sender;
{
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Are you sure?"];
	[alert setInformativeText:@"This will delete the database and all configuration information!"];
	[alert addButtonWithTitle:@"Delete"];
	[alert addButtonWithTitle:@"Cancel"];
	if ([alert runModal] == NSAlertSecondButtonReturn) return;
	NSArray *list = [databaseListController selectedObjects];
	Database *database = [list objectAtIndex:0];
	[database deleteAll];
	[databaseListController remove:sender];
}

- (IBAction)removeHelperTool:(id)sender;
{
	[helper remove];
	[authenticateButton setEnabled:YES];
	[helperToolMessage setHidden:YES];
	[removeButton setEnabled:NO];
}

- (void)removeRequest:(NSNotification *)notification;
{
	Version *version = [notification object];
	[self startTaskProgressSheetAndAllowCancel:NO];
	[taskProgressText insertText:[@"Deleting version " stringByAppendingString:[version name]]];
	[notificationCenter
	 addObserver:self 
	 selector:@selector(removeVersionDone:) 
	 name:kRemoveVersionDone 
	 object:version];
	[version performSelector:@selector(remove) withObject:nil afterDelay:0.1];
}

- (void)removeVersionDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:[notification object]];
	[self refreshInstalledVersionsList];	
	[taskProgressText insertText:@" . . . Done!"];
	[self taskFinishedAfterDelay:0.5];
}

- (void)refreshInstalledVersionsList;
{
	[versionPopupController removeObjects:[versionPopupController arrangedObjects]];
	for (Version *version in [versionListController arrangedObjects]) {
		[version updateIsInstalled];
		if ([version isInstalled]) {
			[versionPopupController addObject:[version name]];
		}
	}
	[lastUpdateDateField setObjectValue:setup.versionsDownloadDate];
}

- (void)selectedDatabase:(Database *)aDatabase;
{
	[logFileListController removeObjects:[logFileListController arrangedObjects]];
	[oldLogFilesText setStringValue:@""];
	[oldTranLogsText setStringValue:@""];
	if (aDatabase == nil) return;
	[logFileListController addObjects:[aDatabase logFiles]];
	[oldLogFilesText setStringValue:[aDatabase descriptionOfOldLogFiles]];
	[oldTranLogsText setStringValue:[aDatabase descriptionOfOldTranLogs]];
}

- (void)setupExceptionHandler;
{
	NSExceptionHandler *handler = [NSExceptionHandler defaultExceptionHandler];
	[handler setExceptionHandlingMask:[handler exceptionHandlingMask] | NSLogOtherExceptionMask];
	[handler setDelegate:self];
}

- (void)startTaskProgressSheetAndAllowCancel:(BOOL)allowCancel;
{
    [NSApp beginSheet:taskProgressPanel
       modalForWindow:[NSApp mainWindow]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
	[taskProgressIndicator setIndeterminate:YES];
	[taskProgressIndicator startAnimation:self];
	[taskCancelButton setEnabled:allowCancel];
}

- (void)taskError:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:task];
	[self criticalAlert:@"Task Failed" details:[[notification userInfo] objectForKey:@"string"]];
	[self taskFinishedAfterDelay:0.5];
}

- (void)taskFinished;
{
	task = nil;
	[taskProgressIndicator stopAnimation:self];
	[taskProgressText setString:[NSMutableString new]];
	[NSApp endSheet:taskProgressPanel];
	[taskProgressPanel orderOut:nil];
}

- (void)taskFinishedAfterDelay:(NSTimeInterval)seconds;
{
	[self performSelector:@selector(taskFinished) withObject:nil afterDelay:seconds];
}

- (void)taskProgress:(NSNotification *)notification;
{
	NSArray *array = [[notification object] componentsSeparatedByString:@"\r"];
	[taskProgressText insertText:[array objectAtIndex:0]];
	for (int i = 1; i < [array count]; ++i) {
		NSString *string = [taskProgressText string];
		NSString *nextLine = [array objectAtIndex:i];
		int lastLF = -1;
		for (int j = 0; j < [string length]; ++j) {
			if (10 == [string characterAtIndex:j]) {
				lastLF = j;
			}
		}
		if (0 < lastLF) {
			NSRange range = {lastLF + 1, [string length] - 1};
			[taskProgressText setSelectedRange:range];
			double value = [nextLine doubleValue];
			if (value) {
				[taskProgressIndicator setIndeterminate:NO];
				[taskProgressIndicator setDoubleValue:value];
			}
		}
		[taskProgressText insertText:nextLine];
	}
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}

- (void)unzipDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:task];
	[self refreshInstalledVersionsList];	
	[self taskFinishedAfterDelay:0.5];
}

- (void)unzipPath:(NSString *)path;
{
	ImportZippedVersion *myTask = [ImportZippedVersion new];
	task = myTask;
	myTask.zipFilePath = path;
	[notificationCenter
	 addObserver:self 
	 selector:@selector(unzipDone:) 
	 name:kTaskDone 
	 object:task];
	[task start];
}

- (IBAction)unzipRequest:(id)sender;
{
	[self verifyNoTask];
	//	get path to zip file
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setDelegate:self];
	int result = [op runModal];
	[op setDelegate:nil];
    if (result != NSOKButton) return;
	[self startTaskProgressSheetAndAllowCancel:NO];
	[self unzipPath:[[[op URLs] objectAtIndex:0] path]];
}

- (void)updateDatabaseList:(id)sender;
{
	NSUInteger index = [databaseListController selectionIndex];
	[databaseListController setAvoidsEmptySelection:NO];
	[databaseListController setSelectedObjects:[NSArray new]];
	[databaseListController setSelectionIndex:index];
	[databaseListController setAvoidsEmptySelection:YES];
}

- (IBAction)updateVersionList:(id)sender;
{
	[self verifyNoTask];
	task = [DownloadVersionList new];
	[notificationCenter
	 addObserver:self 
	 selector:@selector(updateVersionsDone:) 
	 name:kTaskDone 
	 object:task];
	[self startTaskProgressSheetAndAllowCancel:YES];
	[task start];
}

- (void)updateVersionsDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:task];
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObjectModel *managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
	NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Version"];
	
	NSArray *oldVersions = [versionListController arrangedObjects];
	id myTask = task;
	for (NSDictionary *dict in [myTask versions]) {
		Version *oldVersion = nil;
		for (Version *each in oldVersions) {
			if (!oldVersion && [[each name] compare:[dict objectForKey:@"name"]] == NSOrderedSame) {
				oldVersion = each;
			}
		}
		if (oldVersion) {
			if (![oldVersion.date isEqualToDate:[dict objectForKey:@"date"]]) {
				oldVersion.date = [dict objectForKey:@"date"];
			}
		} else {
			Version *version = [[Version alloc]
								initWithEntity:entity 
								insertIntoManagedObjectContext:moc];
			[version setName:[dict objectForKey:@"name"]];
			[version setDate:[dict objectForKey:@"date"]];
			[versionListController insertObject:version atArrangedObjectIndex:0];
		}
	}
	setup.versionsDownloadDate = [NSDate date];
	[self refreshInstalledVersionsList];
	[self taskFinishedAfterDelay:0.5];
}

- (void)verifyNoTask;
{
	if (!task) return;
	AppError(@"Task should not be in progress!");
}

- (NSArray *)versionList;
{
	return [versionListController arrangedObjects];
}

@end
