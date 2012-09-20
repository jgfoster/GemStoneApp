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
#import "GSList.h"
#import "LogFile.h"
#import "Login.h"
#import "StartNetLDI.h"
#import "StartStone.h"
#import "Statmonitor.h"
#import "StopNetLDI.h"
#import "StopStone.h"
#import "Topaz.h"
#import "UnzipVersion.h"
#import "Utilities.h"
#import "Version.h"

#define NotifyMe(aString, aSymbol) \
[notificationCenter addObserver:self selector:@selector(aSymbol:) name:aString object:nil]

@interface NSManagedObject (Setup)
@property(nonatomic, retain) NSNumber *lastDatabaseIdentifier;
@property(nonatomic, retain) NSNumber *taskCloseWhenDoneCode;
@property(nonatomic, retain) NSDate   *versionsDownloadDate;
@end 


@implementation AppController

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
	helper = [Helper new];
	BOOL isCurrent = [helper isCurrent];
	[helperToolMessage setHidden:!isCurrent];
	[authenticateButton setEnabled:!isCurrent];
	[removeButton setEnabled:isCurrent];
	[taskProgressText setFont:[NSFont fontWithName:@"Monaco" size:9]];
	[statmonFileSelectedController setContent:[NSNumber numberWithBool:NO]];
	[repositoryConversionCheckbox setState:NSOffState];
	[upgradeSeasideCheckbox setState:NSOffState];
		
	NotifyMe(kTaskError,				taskError);
	NotifyMe(kTaskProgress,				taskProgress);
	NotifyMe(kTaskStart,				taskStart);
	NotifyMe(kDatabaseStartRequest,		databaseStartRequest);
	NotifyMe(kDatabaseStopRequest,		databaseStopRequest);
	NotifyMe(kDababaseInfoChanged,		updateDatabaseList);
	
	[databaseListController addObserver:self
							 forKeyPath:@"selection"
								options:(NSKeyValueObservingOptionNew)
								context:nil];
	[self performSelector:@selector(loadRequestForSetup)			withObject:nil afterDelay:0.01];
	[self performSelector:@selector(loadRequestForDatabase)			withObject:nil afterDelay:0.02];
	[self performSelector:@selector(loadRequestForLogin)			withObject:nil afterDelay:0.03];
	[self performSelector:@selector(loadRequestForVersion)			withObject:nil afterDelay:0.04];
	[self performSelector:@selector(refreshInstalledVersionsList)	withObject:nil afterDelay:0.05];
	[self performSelector:@selector(refreshUpgradeVersionsList)		withObject:nil afterDelay:0.06];
	[self performSelector:@selector(updateDatabaseState)			withObject:nil afterDelay:0.07];
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

	[self saveData];
}

- (IBAction)cancelTask:(id)sender
{
	if (taskX) {
		if ([taskX isExecuting]) {
			[taskProgressText insertText:@"\n\nSending task cancel request . . ."];
			[taskX cancel];
		} else {	//	Presumably this means that the title was changed to "Close"
			[self taskFinished];
		}
	} else {
		if (0 < [operations operationCount]) {
			[operations cancelAllOperations];
		} else {	//	Presumably this means that the title was changed to "Close"
			[self taskFinished];
		}
	}
}

- (IBAction)clickedDataFile:(id)sender;
{
	[dataFileInfo setString:@""];
	Database *database = [self selectedDatabase];
	if (!database) return;
	NSTableView *dataFileList = sender;
	NSArrayController *arrayController = (NSArrayController *)[dataFileList dataSource];
	NSInteger rowIndex = [dataFileList selectedRow];
	if (rowIndex < 0) return;
	NSString *file = [[arrayController arrangedObjects] objectAtIndex:rowIndex];
	[dataFileInfo setString:[database infoForDataFile:file]];
	[dataFileSizeText setStringValue:[database sizeForDataFile:file]];
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
	[taskProgressText insertText:@"\n============================\n"];
	[notificationCenter removeObserver:self name:nil object:taskX];
	Database *database = [(DatabaseTask *) taskX database];
	Statmonitor *monitor = [Statmonitor forDatabase:database];
	[monitor start];
	NSString *key = [[database identifier] stringValue];
	[statmonitors setValue:monitor forKey:key];
	[self updateDatabaseList:nil];
	[self performSelector:@selector(updateDatabaseList:) withObject:nil afterDelay:1.0];
	[database performSelector:@selector(refreshStatmonFiles) withObject:nil afterDelay:0.4];
	[statmonTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
	NSString *path = [database restorePath];
	if (path) {
		[self doRunLoopFor:0.1];
		[taskProgressText insertText:@"\n============================\n"];
		Login *login = [self defaultLoginForDatabase:database];
		Topaz *myTask = [Topaz login:login toDatabase:database];
		taskX = myTask;
		[notificationCenter
		 addObserver:self 
		 selector:@selector(databaseStartRestoreDone:) 
		 name:kTaskDone 
		 object:taskX];
		[myTask restoreFromBackup];
	} else {
		[self taskFinishedAfterDelay];
	}
}

- (void)databaseStartRestoreDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:taskX];
	[self taskFinishedAfterDelay];
}

- (void)databaseStartStoneDone:(NSNotification *)notification;
{
	[taskProgressText insertText:@"\n============================\n"];
	[notificationCenter removeObserver:self name:nil object:taskX];
	Database *database = [(DatabaseTask *) taskX database];
	StartNetLDI *startNetLdiTask = [StartNetLDI forDatabase:database];
	taskX = startNetLdiTask;
	[notificationCenter
	 addObserver:self 
	 selector:@selector(databaseStartNetLdiDone:) 
	 name:kTaskDone 
	 object:taskX];
	[taskX start];
}

- (void)databaseStartRequest:(NSNotification *)notification;
{
	[self verifyNoTask];
	StartStone *myTask = [StartStone forDatabase:[notification object]];
	taskX = myTask;
	[notificationCenter
	 addObserver:self 
	 selector:@selector(databaseStartStoneDone:) 
	 name:kTaskDone 
	 object:taskX];
	[taskX start];
}

- (void)databaseStopNetLdiDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:taskX];
	Database *database = [(DatabaseTask *) taskX database];
	NSString *key = [[database identifier] stringValue];
	Statmonitor *monitor = [statmonitors valueForKey:key];
	[statmonitors setValue:nil forKey:key];
	[monitor cancel];
	[self updateDatabaseList:nil];
	[database performSelector:@selector(refreshStatmonFiles) withObject:nil afterDelay:0.4];
	[statmonTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
	[self taskFinishedAfterDelay];
}

- (void)databaseStopStoneDone:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:taskX];
	Database *database = [(DatabaseTask *) taskX database];
	[database archiveCurrentLogFiles];
	[database archiveCurrentTransactionLogs];
	StopNetLDI *stopNetLdiTask = [StopNetLDI forDatabase:database];
	taskX = stopNetLdiTask;
	[notificationCenter
	 addObserver:self 
	 selector:@selector(databaseStopNetLdiDone:) 
	 name:kTaskDone 
	 object:taskX];
	[taskX start];
}

- (void)databaseStopRequest:(NSNotification *)notification;
{
	[self verifyNoTask];
	StopStone *myTask = [StopStone forDatabase:[notification object]];
	taskX = myTask;
	[notificationCenter
	 addObserver:self 
	 selector:@selector(databaseStopStoneDone:) 
	 name:kTaskDone 
	 object:taskX];
	[taskX start];
	[taskProgressText insertText:@"Initiating database shutdown . . .\n\n"];
}

- (Login *)defaultLoginForDatabase:(Database *)database;
{
	NSManagedObjectModel *managedObjectModel = [[managedObjectContext persistentStoreCoordinator] managedObjectModel];
	NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Login"];
	Login *login = [[Login alloc]
					initWithEntity:entity
					insertIntoManagedObjectContext:managedObjectContext];
	[login initializeForDatabase:database];
	return login;
}

- (IBAction)defaultLogin:(id)sender;
{
	Login *login = [self defaultLoginForDatabase:[self selectedDatabase]];
	NSLog(@"login = %@", login);
}

- (IBAction)deleteStatmonFiles:(id)sender;
{
	Database *database = [self selectedDatabase];
	NSIndexSet *indexes = [statmonTableView selectedRowIndexes];
	[database deleteStatmonFilesAtIndexes:indexes];
}

- (void)doRunLoopFor:(double)seconds;
{
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

- (IBAction)doUpgrade:(id)sender;
{
	Database *database = [self selectedDatabase];
	NSString *oldVersion = [database version];
	NSString *newVersion = [[upgradePopupController selectedObjects] objectAtIndex:0];
	BOOL needsConversion = [repositoryConversionCheckbox state];
	BOOL doSeasideUpgrade = [upgradeSeasideCheckbox state];
	NSLog(@"doUpgrade: from %@ to %@ with %i and %i", oldVersion, newVersion, needsConversion, doSeasideUpgrade);
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(unsigned int)aMask;
{
	NSString *string = [NSString stringWithFormat:@"%@\n\nSee Console for details.", [exception reason]];
	[self criticalAlert:@"Internal Application Error!" details:string];
	[self taskFinishedAfterDelay];
	return YES;
}

- (id)init;
{
	if (self = [super init]) {
		[[Utilities new] setupGlobals:self];
		[self initManagedObjectContext];
		[self setupExceptionHandler];
		statmonitors = [NSMutableDictionary new];
		operations = [NSOperationQueue new];
		[operations setName:@"OperationQueue"];
	}
	return self;
}

- (void) initManagedObjectContext;
{
    managedObjectContext = [[NSManagedObjectContext alloc] init];
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc]
												 initWithManagedObjectModel: model];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
	NSURL *url = [NSURL 
				  fileURLWithPath:[basePath stringByAppendingString:@"/data.binary"] 
				  isDirectory:NO];
    NSError *error = nil;
    NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:NSBinaryStoreType
															configuration:nil
																	  URL:url
																  options:nil
																	error:&error];
    if (!newStore) {
        AppError(@"Store Configuration Failure\n%@",
				 ([error localizedDescription] != nil) ?
				 [error localizedDescription] : @"Unknown Error");
    }
}

- (IBAction)installHelperTool:(id)sender
{
	[helper install];
	[authenticateButton setEnabled:NO];
	[helperToolMessage setHidden:NO];
	[removeButton setEnabled:YES];
}

- (void)loadRequestForDatabase;
{
	[self loadRequest:@"Database" toController:databaseListController];
}

- (void)loadRequestForLogin;
{
	[self loadRequest:@"Login" toController:loginListController];
}

- (void)loadRequestForSetup;
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Setup" inManagedObjectContext:managedObjectContext];
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:entity];
	NSError *error = nil;
	NSArray *list = [managedObjectContext executeFetchRequest:request error:&error];
	if (!list || ![list count]) {
		mySetup = [NSEntityDescription insertNewObjectForEntityForName:@"Setup" inManagedObjectContext:managedObjectContext];
	} else {
		mySetup = [list objectAtIndex:0];
	}
}

- (void)loadRequestForVersion;
{
	[self loadRequest:@"Version" toController:versionListController];
}

- (void)loadRequest:(NSString *)requestName toController:(NSArrayController *)controller;
{
	NSError *error = nil;
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:requestName];
	NSArray *list = [managedObjectContext executeFetchRequest:request error:&error];
	if (!list) {
        AppError(@"Data load failed\n%@",
			  ([error localizedDescription] != nil) ?
			  [error localizedDescription] : @"Unknown Error");
		exit(1);		// not much point in running if we can't load our data
	}
	for (id each in list) {		// iterate over each object and cause the "fault" to be replaced with the object
		[each valueForKey:@"indexInArray"];
	}
	NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"indexInArray" ascending:YES];
	NSArray *descriptors = [NSArray arrayWithObjects:descriptor, nil];
	NSArray *sortedArray = [list sortedArrayUsingDescriptors:descriptors];
	[controller setSelectsInsertedObjects:NO];
	[controller addObjects:sortedArray];
	[controller setSelectsInsertedObjects:YES];
}

- (Database *)mostAdvancedDatabase;
{
	NSArray *databases = [databaseListController arrangedObjects];
	if (0 == [databases count]) return nil;
	Database *database = [databases objectAtIndex:0];
	for (Database *each in databases) {
		if ([[database version]compare:[each version]]== NSOrderedAscending) {
			database = each;
		}
	}
	return database;
}

- (NSString *)mostAdvancedVersion;
{
	NSArray *versions = [self versionList];
	Version *aVersion = [versions objectAtIndex:0];
	NSString *version = aVersion.name;
	for (Version *each in versions) {
		if ([version compare:each.name]== NSOrderedAscending) {
			version = each.name;
		}
	}
	return version;
}

- (NSNumber *)nextDatabaseIdentifier;
{
	NSNumber *identifier = [mySetup lastDatabaseIdentifier];
	identifier = [NSNumber numberWithInt:[identifier intValue] + 1];
	[mySetup setLastDatabaseIdentifier:identifier];
	return identifier;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if (object == databaseListController) {
		[self selectedDatabase:[self selectedDatabase]];
		return;
	}
	NSLog(@"keyPath = %@; object = %@; change = %@; context = %@", keyPath, object, change, context);
}

- (IBAction)openStatmonFiles:(id)sender;
{
	Database *database = [self selectedDatabase];
	NSIndexSet *indexes = [statmonTableView selectedRowIndexes];
	[database openStatmonFilesAtIndexes:indexes];
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
	if ([database isRunning]) {
		[database stopDatabase];
		while ([taskProgressPanel isKeyWindow]) {
			[self doRunLoopFor:0.1];
		}
	}
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

- (void)refreshInstalledVersionsList;
{
	[versionPopupController removeObjects:[versionPopupController arrangedObjects]];
	for (Version *version in [versionListController arrangedObjects]) {
		[version updateIsInstalled];
		if ([version isInstalled]) {
			[versionPopupController addObject:[version name]];
		}
	}
	[lastUpdateDateField setObjectValue:[mySetup versionsDownloadDate]];
}

- (void)refreshUpgradeVersionsList;
{
	Database *database = [self selectedDatabase];
	[upgradePopupController removeObjects:[upgradePopupController arrangedObjects]];
	if (database) {
		NSString *currentVersion = [database version];
		for (Version *version in [versionListController arrangedObjects]) {
			NSString *name = [version name];
			if ([version isInstalled] && [currentVersion compare:name] == NSOrderedAscending) {
				[upgradePopupController addObject:name];
			}
		}
	}
}

- (void)saveData;
{
	if (![managedObjectContext hasChanges]) return;
	
	NSError *error = nil;
	if (![managedObjectContext save:&error]) {
		AppError(@"Data save failed\n%@",
				 ([error localizedDescription] != nil) ?
				 [error localizedDescription] : @"Unknown Error");
	}
}

- (Database *)selectedDatabase;
{
	NSArray *list = [databaseListController selectedObjects];
	Database *database = nil;
	if (0 < [list count]) {
		database = [list objectAtIndex:0];
	}
	return database;
}

- (void)selectedDatabase:(Database *)aDatabase;
{
	[logFileListController removeObjects:[logFileListController arrangedObjects]];
	[dataFileListController removeObjects:[dataFileListController arrangedObjects]];
	[statmonTableView setDataSource:nil];
	[statmonTableView setDelegate:nil];
	[statmonTableView setTarget:nil];
	[oldLogFilesText setStringValue:@""];
	[oldTranLogsText setStringValue:@""];
	[dataFileInfo setString:@""];
	if (aDatabase == nil) return;
	[aDatabase refreshStatmonFiles];
	[logFileListController addObjects:[aDatabase logFiles]];
	[oldLogFilesText setStringValue:[aDatabase descriptionOfOldLogFiles]];
	[oldTranLogsText setStringValue:[aDatabase descriptionOfOldTranLogs]];
	[dataFileListController addObjects:[aDatabase dataFiles]];
	[statmonTableView setDataSource:aDatabase];
	[statmonTableView setDelegate:aDatabase];
	[statmonTableView setTarget:aDatabase];
	[statmonTableView setDoubleAction:@selector(doubleClickStatmon:)];
	[statmonTableView reloadData];
	[self refreshUpgradeVersionsList];
	[repositoryConversionCheckbox setState:NSOffState];
	[upgradeSeasideCheckbox setState:NSOffState];
}

- (void)setIsStatmonFileSelected:(BOOL)flag;
{
	[statmonFileSelectedController setContent:[NSNumber numberWithBool:flag]];
}

- (void)setupExceptionHandler;
{
	NSExceptionHandler *handler = [NSExceptionHandler defaultExceptionHandler];
	[handler setExceptionHandlingMask:[handler exceptionHandlingMask] | NSLogOtherExceptionMask];
	[handler setDelegate:self];
}

- (NSTableView *)statmonTableView;
{
	return statmonTableView;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
{
	if (tabViewItem == gsListTabViewItem) {
		[self updateDatabaseState];
		return;
	}
}

- (IBAction)taskCloseWhenDone:(id)sender;
{
	NSButton *myButton = sender;
	NSInteger state = [myButton state];
	[mySetup setTaskCloseWhenDoneCode:[NSNumber numberWithInteger:state]];
}

- (void)taskError:(NSNotification *)notification;
{
	[notificationCenter removeObserver:self name:nil object:taskX];
	[self performSelectorOnMainThread:@selector(taskErrorA:) withObject:notification waitUntilDone:NO];
}

- (void)taskErrorA:(NSNotification *)notification;
{
	[self criticalAlert:@"Task Failed" details:[[notification userInfo] objectForKey:@"string"]];
	[self taskFinishedAfterDelay];
}

- (void)taskFinished;
{
	[self performSelectorOnMainThread:@selector(taskFinishedA) withObject:nil waitUntilDone:NO];
}

- (void)taskFinishedA;
{
	taskX = nil;
	[taskProgressText setString:[NSMutableString new]];
	[NSApp endSheet:taskProgressPanel];
	[taskProgressPanel orderOut:nil];
}

- (void)taskFinishedAfterDelay;
{
	[self performSelectorOnMainThread:@selector(taskFinishedAfterDelayA) withObject:nil waitUntilDone:NO];
}

- (void)taskFinishedAfterDelayA;
{
	[taskProgressIndicator stopAnimation:self];
	[taskCancelButton setTitle:@"Close"];
	[self performSelector:@selector(taskFinishedAfterDelayB) withObject:nil afterDelay:1.0];
}

- (void)taskFinishedAfterDelayB;
{
	if ([[mySetup taskCloseWhenDoneCode] boolValue]) {
		[self taskFinishedA];
	}
}

- (void)taskProgress:(NSNotification *)notification;
{
	[self performSelectorOnMainThread:@selector(taskProgressA:)
						   withObject:[notification object] 
						waitUntilDone:NO];
}

- (void)taskProgressA:(NSString *)aString;
{
	NSArray *array = [aString componentsSeparatedByString:@"\r"];
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
}

- (void)taskStart:(NSNotification *)notification;
{
	[self performSelectorOnMainThread:@selector(taskStartA:) 
						   withObject:[notification object] 
						waitUntilDone:NO];
}

- (void)taskStartA:(NSString *)aString;
{
	if (![taskProgressPanel isVisible]) {
		[NSApp beginSheet:taskProgressPanel
		   modalForWindow:[NSApp mainWindow]
			modalDelegate:self
		   didEndSelector:nil
			  contextInfo:nil];
		[taskProgressIndicator setIndeterminate:YES];
		[taskProgressIndicator startAnimation:self];
		[taskCancelButton setTitle:@"Cancel"];
		[taskCloseWhenDoneButton setState:[[mySetup taskCloseWhenDoneCode] integerValue]];
	}
	[self taskProgressA:aString];
}

- (void)unzipPath:(NSString *)path;
{
	NSLog(@"how did we get here?");
}

- (void)updateDatabaseList:(id)sender;
{
	NSUInteger index = [databaseListController selectionIndex];
	[databaseListController setAvoidsEmptySelection:NO];
	[databaseListController setSelectedObjects:[NSArray new]];
	[databaseListController setSelectionIndex:index];
	[databaseListController setAvoidsEmptySelection:YES];
}

- (void)updateDatabaseState;
{
	Database *database = [self mostAdvancedDatabase];
	if (!database) return;
	NSArray *list = [GSList processListUsingDatabase:database];
	for (database in [databaseListController arrangedObjects]) {
		[database gsList:list];
	}
	[processListController removeObjects:[processListController arrangedObjects]];
	[processListController addObjects:list];
	[databaseTableView reloadData];
}

- (void)verifyNoTask;
{
	if (!taskX && ![operations operationCount]) return;
	AppError(@"Task should not be in progress!");
}

- (void)versionDownloadRequest:(Version *)aVersion;
{
	[self verifyNoTask];
	[self taskStartA:[NSString stringWithFormat:@"Downloading %@ . . .\n", [aVersion name]]];
	DownloadVersion *download = [DownloadVersion new];
	[download setVersion:aVersion];
	
	UnzipVersion *unzip = [UnzipVersion new];
	unzip.zipFilePath = [download zipFilePath];
	[unzip addDependency:download];
	__block Task *blockTask = unzip;
	[unzip setCompletionBlock:^(){
		[self performSelectorOnMainThread:@selector(versionUnzipDone:) 
							   withObject:blockTask
							waitUntilDone:NO];
	}];
	[operations addOperation:download];
	[operations addOperation:unzip];
}

- (NSArray *)versionList;
{
	return [versionListController arrangedObjects];
}

- (void)versionListDownloadDone:(DownloadVersionList *)download;
{
	if (![download isCancelled]) {
		NSManagedObjectModel *managedObjectModel = [[managedObjectContext persistentStoreCoordinator] managedObjectModel];
		NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Version"];
		
		NSArray *oldVersions = [versionListController arrangedObjects];
		for (NSDictionary *dict in [download versions]) {
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
									insertIntoManagedObjectContext:managedObjectContext];
				[version setName:[dict objectForKey:@"name"]];
				[version setDate:[dict objectForKey:@"date"]];
				[versionListController insertObject:version atArrangedObjectIndex:0];
			}
		}
		[mySetup setVersionsDownloadDate:[NSDate date]];
		[self refreshInstalledVersionsList];
		[self refreshUpgradeVersionsList];
		[self taskProgressA:@"New version list received!"];
	}
	[self taskFinishedAfterDelay];
}

- (IBAction)versionListDownloadRequest:(id)sender;
{
	[self verifyNoTask];
	[self taskStartA:@"Obtaining GemStone/S 64 Bit version list ...\n"];
	DownloadVersionList *task = [DownloadVersionList new];
	__block Task *blockTask = task;
	[task setCompletionBlock:^(){
		[self performSelectorOnMainThread:@selector(versionListDownloadDone:) 
							   withObject:blockTask
							waitUntilDone:NO];
	}];
	[operations addOperation:task];
}

- (void)versionRemoveDone;
{
	[self refreshInstalledVersionsList];
	[self refreshUpgradeVersionsList];
	[taskProgressText insertText:@" . . . Done!"];
	[self taskFinishedAfterDelay];
}

- (void)versionRemoveRequest:(Version *)aVersion;
{
	[self verifyNoTask];
	[self taskStartA:@"Removing GemStone/S 64 Bit product tree . . .\n"];
	NSInvocationOperation *remove = [[NSInvocationOperation alloc] 
									 initWithTarget:aVersion
									 selector:@selector(remove) 
									 object:nil];
	[operations addOperation:remove];
	
	NSInvocationOperation *update = [[NSInvocationOperation alloc] 
									 initWithTarget:self 
									 selector:@selector(versionRemoveDone) 
									 object:nil];
	[update addDependency:remove];
	[operations addOperation:update];
}

- (void)versionUnzipDone:(Task *)aTask;
{
	if (![aTask isCancelled]) {
		[self refreshInstalledVersionsList];
		[self refreshUpgradeVersionsList];
		[self taskProgressA:@"Finished import of zip file!"];
	}
	[self taskFinishedAfterDelay];
}

- (IBAction)versionUnzipRequest:(id)sender;
{
	[self verifyNoTask];
	NSOpenPanel *op = [NSOpenPanel openPanel];		//	get path to zip file
	[op setDelegate:self];
	int result = [op runModal];
	[op setDelegate:nil];
    if (result != NSOKButton) return;
	[self taskStartA:@"Starting import of zip file . . .\n"];
	
	UnzipVersion *task = [UnzipVersion new];
	__block Task *blockTask = task;
	[task setZipFilePath: [[[op URLs] objectAtIndex:0] path]];
	[task setCompletionBlock:^(){
		[self performSelectorOnMainThread:@selector(versionUnzipDone:) 
							   withObject:blockTask
							waitUntilDone:NO];
	}];
	[operations addOperation:task];
	
}

@end
