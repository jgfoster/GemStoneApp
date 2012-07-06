//
//  AppController.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "AppController.h"
#import "NSFileManager+DirectoryLocations.h"
#import "Database.h"
#import "DownloadVersionList.h"
#import "ImportZippedVersion.h"
#import "Login.h"
#import "Version.h"
#import "DownloadVersion.h"
#import "StartStone.h"

#define kTaskCancelRequest @"cancelTaskRequest"

@interface AppController ()
- (void)criticalAlert:(NSString *)string;
- (void)loadRequest:(NSString *)requestName toController:(NSArrayController *)arrayController;
- (void)refreshInstalledVersionsList;
- (void)startTaskProgressSheetAndAllowCancel:(BOOL)allowCancel;
- (void)taskFinishedAfterDelay:(NSTimeInterval)seconds;
- (void)unzipPath:(NSString *)path;
@end

@implementation AppController

@synthesize setup;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
	helper = [Helper new];
	BOOL isCurrent = [helper isCurrent];
	[helperToolMessage setHidden:!isCurrent];
	[authenticateButton setEnabled:!isCurrent];
	
	[self loadSetup];
	[self loadRequest:@"Database" toController:databaseListController];
	[self loadRequest:@"Login" toController:loginListController];
	[self loadRequest:@"Version" toController:versionListController];
	[self refreshInstalledVersionsList];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(taskProgress:) 
	 name:kTaskProgress
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(downloadRequest:)
	 name:kDownloadRequest
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(removeRequest:)
	 name:kRemoveRequest
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(databaseStartRequest:)
	 name:kDatabaseStartRequest
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(databaseStopRequest:)
	 name:kDatabaseStopRequest
	 object:nil];
	
	[taskProgressText setFont:[NSFont fontWithName:@"Monaco" size:9]];
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
		NSLog(@"Data save failed\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
	}
}

- (IBAction)cancelTask:(id)sender
{
	if (!task) return;
	[task performSelector:@selector(cancelTask)];
	task = nil;
	[self taskFinishedAfterDelay:0];
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

- (void)databaseStartDone:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:task];
	task = nil;	

	[self taskFinishedAfterDelay:0.5];
}

- (void)databaseStartError:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:task];
	task = nil;	
	[self criticalAlert:[[notification userInfo] objectForKey:@"string"]];
	[self taskFinishedAfterDelay:0.5];
}

- (void)databaseStartRequest:(NSNotification *)notification;
{
	if (task) {
		[NSException raise:NSInternalInconsistencyException
					format:@"Task should not be in progress!"];	
	}
	StartStone *myTask = task = [StartStone new];
	[myTask setDatabase:[notification object]];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(databaseStartDone:) 
	 name:kTaskDone 
	 object:task];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(databaseStartError:) 
	 name:kTaskError 
	 object:task];
	[self startTaskProgressSheetAndAllowCancel:YES];
	[task start];
}

- (void)databaseStopRequest:(NSNotification *)notification;
{
	
}

- (void)downloadDone:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:task];
	task = nil;	
	[self unzipPath:[[notification object] zipFilePath]];
}

- (void)downloadError:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:task];
	task = nil;	
	[self criticalAlert:[[notification userInfo] objectForKey:@"string"]];
	[self taskFinishedAfterDelay:0.5];
}

- (void)downloadRequest:(NSNotification *)notification;
{
	if (task) {
		[NSException raise:NSInternalInconsistencyException
					format:@"Task should not be in progress!"];	
	}
	DownloadVersion *myTask = task = [DownloadVersion new];
	[myTask setVersion:[notification object]];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(downloadDone:) 
	 name:kTaskDone 
	 object:task];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(downloadError:) 
	 name:kTaskError 
	 object:task];
	[self startTaskProgressSheetAndAllowCancel:YES];
	[task start];
}

- (IBAction)installHelperTool:(id)sender
{
	NSString *errorString = [helper install];
	if (errorString) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert setMessageText:@"Installation failed:"];
		[alert setInformativeText:errorString];
		[alert addButtonWithTitle:@"Dismiss"];
		[alert runModal];
	} else {
		[authenticateButton setEnabled:NO];
		[helperToolMessage setHidden:NO];
	}
}

- (void)loadRequest:(NSString *)requestName toController:(NSArrayController *)controller;
{
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSError *error = nil;
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:requestName];
	NSArray *list = [moc executeFetchRequest:request error:&error];
	if (!list) {
        NSLog(@"Data load failed\n%@",
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
	NSString *appSupDir = [[NSFileManager defaultManager] applicationSupportDirectory];
	NSMutableString *path = [NSMutableString stringWithString:appSupDir];
	[path appendString:@"/data.binary"];

    NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
	
    NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:NSBinaryStoreType
															configuration:nil
																	  URL:url
																  options:nil
																	error:&error];
    if (newStore == nil) {
        NSLog(@"Store Configuration Failure\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
    }
	return moc;
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

- (void)removeRequest:(NSNotification *)notification;
{
	Version *version = [notification object];
	[self startTaskProgressSheetAndAllowCancel:NO];
	[taskProgressText insertText:[@"Deleting version " stringByAppendingString:[version name]]];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(removeVersionDone:) 
	 name:kRemoveVersionDone 
	 object:version];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(removeVersionError:) 
	 name:kRemoveVersionError 
	 object:version];
	[version performSelector:@selector(remove) withObject:nil afterDelay:0.1];
}

- (void)removeVersionDone:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[notification object]];
	[self refreshInstalledVersionsList];	
	[taskProgressText insertText:@"...Done!"];
	[self taskFinishedAfterDelay:1];
}

- (void)removeVersionError:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[notification object]];
	[self criticalAlert:[[notification object] localizedDescription]];
	[self taskFinishedAfterDelay:0];
}

- (void)removeVersionStart:(NSNotification *)notification;
{
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

- (void)startTaskProgressSheetAndAllowCancel:(BOOL)allowCancel;
{
    [NSApp beginSheet:taskProgressPanel
       modalForWindow:[NSApp mainWindow]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];
	[taskProgressIndicator startAnimation:self];
	[taskCancelButton setEnabled:allowCancel];
}

- (void)taskFinished;
{
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
	[taskProgressText insertText:[notification object]];
}

- (void)unzipDone:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:task];
	task = nil;
	[self refreshInstalledVersionsList];	
	[self taskFinishedAfterDelay:0.5];
}

- (void)unzipError:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:task];
	task = nil;
	[self criticalAlert:[[notification userInfo] objectForKey:@"string"]];
	[self taskFinishedAfterDelay:0];
}

- (void)unzipProgress:(NSNotification *)notification;
{
	[taskProgressText insertText:[[notification userInfo] objectForKey:@"string"]];
}

- (void)unzipPath:(NSString *)path;
{
	ImportZippedVersion *myTask = task = [ImportZippedVersion new];
	myTask.zipFilePath = path;
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(unzipDone:) 
	 name:kImportDone 
	 object:task];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(unzipError:) 
	 name:kImportError
	 object:task];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(unzipProgress:) 
	 name:kImportProgress
	 object:task];
	[task start];
}

- (IBAction)unzipRequest:(id)sender;
{
	if (task) {
		[NSException raise:NSInternalInconsistencyException
					format:@"Task should not be in progress!"];	
	}
	
	//	get path to zip file
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setDelegate:self];
    if ([op runModal] != NSOKButton) return;
	[self startTaskProgressSheetAndAllowCancel:NO];
	[self unzipPath:[[[op URLs] objectAtIndex:0] path]];
}

- (IBAction)updateVersionList:(id)sender;
{
	if (task) {
		[NSException raise:NSInternalInconsistencyException
					format:@"Task should not be in progress!"];	
	}
	task = [DownloadVersionList new];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self 
	 selector:@selector(updateVersionsDone:) 
	 name:kTaskDone 
	 object:task];
	[self startTaskProgressSheetAndAllowCancel:YES];
	[task start];
}

- (void)updateVersionsDone:(NSNotification *)notification;
{
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self 
	 name:nil 
	 object:task];
	
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSManagedObjectModel *managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
	NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Version"];
	
	NSArray *oldVersions = [versionListController arrangedObjects];
	for (NSDictionary *dict in [task versions]) {
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
	[self refreshInstalledVersionsList];
	task = nil;
	setup.versionsDownloadDate = [NSDate date];
	[self taskFinishedAfterDelay:0.5];
}

@end
