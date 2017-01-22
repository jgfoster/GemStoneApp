//
//  AppController.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import <ExceptionHandling/NSExceptionHandler.h>

#import "AppController.h"
#import "Database.h"
#import "DownloadVersion.h"
#import "DownloadVersionList.h"
#import "GSList.h"
#import "Helper.h"
#import "LogFile.h"
#import "StartNetLDI.h"
#import "StartStone.h"
#import "Statmonitor.h"
#import "StopNetLDI.h"
#import "StopStone.h"
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

@synthesize managedObjectContext;

- (IBAction)addDatabase:(id)sender;
{
	NSManagedObjectModel *managedObjectModel = [[managedObjectContext persistentStoreCoordinator] managedObjectModel];
	NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Database"];
	Database *database = [[Database alloc]
						initWithEntity:entity
						insertIntoManagedObjectContext:managedObjectContext];
	[databaseListController addObject:database];
}

- (void)addOperation:(NSOperation *)anOperation;
{
	[operations addOperation:anOperation];
}

- (IBAction)addToEtcHosts:(id)sender;
{
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
    helper = [Helper new];
	[taskProgressText setFont:[NSFont fontWithName:@"Monaco" size:9]];
	[statmonFileSelectedController setContent:[NSNumber numberWithBool:NO]];
	[repositoryConversionCheckbox setState:NSOffState];
	[upgradeSeasideCheckbox setState:NSOffState];
		
	[databaseListController addObserver:self
							 forKeyPath:@"selection"
								options:(NSKeyValueObservingOptionNew)
								context:nil];
	[self performSelector:@selector(loadRequestForSetup)			withObject:nil afterDelay:0.01];
	[self performSelector:@selector(loadRequestForDatabase)			withObject:nil afterDelay:0.02];
	[self performSelector:@selector(loadRequestForVersion)			withObject:nil afterDelay:0.04];
	[self performSelector:@selector(refreshInstalledVersionsList)	withObject:nil afterDelay:0.05];
	[self performSelector:@selector(refreshUpgradeVersionsList)		withObject:nil afterDelay:0.06];
	[self performSelector:@selector(updateDatabaseState)			withObject:nil afterDelay:0.07];
	[self performSelector:@selector(checkForSetupRequired)			withObject:nil afterDelay:0.10];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification;
{
	NSArray *list;
	list = [versionListController arrangedObjects];
	for (int i = 0; i < [list count]; ++i) {
		Version *version = [list objectAtIndex:i];
		if (version.indexInArray != [NSNumber numberWithInt:i]) {
			version.indexInArray = [NSNumber numberWithInt:i];
		}
	}
	list = [databaseListController arrangedObjects];
	for (int i = 0; i < [list count]; ++i) {
		Database *database = [list objectAtIndex:i];
		if (database.indexInArray != [NSNumber numberWithInt:i]) {
			database.indexInArray = [NSNumber numberWithInt:i];
		}
	}

	[self saveData];
    [helper terminate];
}

- (IBAction)cancelTask:(id)sender;
{
	if (0 < [operations operationCount]) {
		[operations cancelAllOperations];
		[self taskFinishedAfterDelay];
	} else {	//	Presumably this means that the title was changed to "Close"
		[self taskFinished];
	}
}

- (void)checkForSetupRequired;
{
	[self performSelectorOnMainThread:@selector(checkForSetupRequiredA)
						   withObject:nil
						waitUntilDone:YES];
}

- (void)checkForSetupRequiredA;
{
	if (0 == [[self versionList] count]) {
		[topTabView selectFirstTabViewItem:nil];
	}
}

- (IBAction)clickedDataFile:(id)sender;
{
	[dataFileInfo setString:@""];
	[dataFileSizeText setStringValue:@""];
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

- (IBAction)closeInfoPanel:(id)sender;
{
	[NSApp endSheet:infoPanel];
	[infoPanel orderOut:nil];
}

- (void)criticalAlert:(NSString *)textString details:(NSString *)detailsString;
{
	NSArray *args = [NSArray arrayWithObjects:textString, detailsString, nil];
	[self performSelectorOnMainThread:@selector(criticalAlertA:) withObject:args waitUntilDone:NO];
}

- (void)criticalAlertA:(NSArray *)args;
{
	NSString *textString = [args objectAtIndex:0];
	NSString *detailsString = [args objectAtIndex:1];
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert setMessageText:textString];
	[alert setInformativeText:detailsString];
	[alert addButtonWithTitle:@"Dismiss"];
	[alert runModal];
}

- (Boolean)databaseExistsForVersion:(Version *)version;
{
	for (Database *eachDatabase in [databaseListController arrangedObjects]) {
		if ([[eachDatabase version] isEqualToString:[version name]]) {
			return YES;
		}
	}
	return false;
}

- (void)databaseStartDone:(Database *)aDatabase;
{
	[self updateDatabaseList:nil];
	[statmonTableView	performSelector:@selector(reloadData)			withObject:nil afterDelay:0.5];
	[self				performSelector:@selector(updateDatabaseList:)	withObject:nil afterDelay:1.0];
	[self taskFinishedAfterDelay];
}

- (void)databaseStopDone:(Database *)aDatabase;
{
	[self updateDatabaseList:nil];
	[statmonTableView	performSelector:@selector(reloadData)			withObject:nil afterDelay:0.5];
	[self taskFinishedAfterDelay];
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

- (void)ensureSharedMemory;
{
	[helper ensureSharedMemory];
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(NSUInteger)aMask;
{
	NSString *string = [NSString stringWithFormat:@"%@\n\nSee Console for details.", [exception reason]];
	[self criticalAlert:@"Internal Application Error!" details:string];
	[self taskFinishedAfterDelay];
	return YES;
}

- (IBAction)gemToolsSession:(id)sender;
{
	Database *database = [self selectedDatabase];
	NSString *string = [database gemToolsLogin];
	[infoPanelTextView setString:string];
    [[NSApp mainWindow]beginSheet:infoPanel completionHandler:^(NSModalResponse returnCode) {
        return;
    }];
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
				  fileURLWithPath:[self pathToDataFile]
				  isDirectory:NO];
    NSError *error = nil;
    NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:NSBinaryStoreType
															configuration:nil
																	  URL:url
																  options:nil
																	error:&error];
    if (!newStore) {
		NSString *myString = ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error";
        AppError(@"Store Configuration Failure\n%@", myString);
    }
}

- (IBAction)installHelperTool:(id)sender
{
	[helper install];
}

- (void)loadRequestForDatabase;
{
	[self loadRequest:@"Database" toController:databaseListController];
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
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	[versionListController setSortDescriptors:sortDescriptors];
	[self loadRequest:@"Version" toController:versionListController];
}

- (void)loadRequest:(NSString *)requestName toController:(NSArrayController *)controller;
{
	NSError *error = nil;
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:requestName];
	NSArray *list = [managedObjectContext executeFetchRequest:request error:&error];
	if (!list) {
		NSString *myString = ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error";
        AppError(@"Data load failed\n%@",myString);
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
	NSString *name = nil;
	for (Version *each in [self versionList]) {
		if ([each isInstalled] && (name == nil || [name compare:each.name]== NSOrderedAscending)) {
			name = each.name;
		}
	}
	return name;
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

- (IBAction)openBrowserOnAvailableVersions:(id)sender;
{
	NSURL *url = [NSURL URLWithString:@"http://seaside.gemtalksystems.com/downloads/i386.Darwin/"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openDefaultConfigFile:(id)sender;
{
	[[self selectedDatabase] openDefaultConfigFile];

}

- (IBAction)openGemConfigFile:(id)sender;
{
	[[self selectedDatabase] openGemConfigFile];
}

- (IBAction)openStatmonFiles:(id)sender;
{
	NSIndexSet *indexes = [statmonTableView selectedRowIndexes];
	[[self selectedDatabase] openStatmonFilesAtIndexes:indexes];
}

- (IBAction)openStoneConfigFile:(id)sender;
{
	[[self selectedDatabase] openStoneConfigFile];
}

- (IBAction)openSystemConfigFile:(id)sender;
{
	[[self selectedDatabase] openSystemConfigFile];
}

- (NSString *)pathToDataFile;
{
	return [basePath stringByAppendingString:@"/data.binary"];
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
	[managedObjectContext deleteObject:database];
	[self saveData];
}

- (IBAction)removeHelperTool:(id)sender;
{
	[helper remove];
}

- (void)removeVersionDone;
{
	[self refreshInstalledVersionsList];
	[self refreshUpgradeVersionsList];
	[taskProgressText insertText:@" . . . Done!"];
	[self taskFinishedAfterDelay];
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
	BOOL hasChanges = [managedObjectContext hasChanges];
	if (!hasChanges) { return; }
	
	NSError *error = nil;
	BOOL saveWasSuccessful = [managedObjectContext save:&error];
	if (!saveWasSuccessful) {
		NSString *myString = [error localizedDescription] != nil ? [error localizedDescription] : @"Unknown Error";
        AppError(@"Data save failed\n%@",myString);
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
	[aDatabase createConfigFiles];
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

- (IBAction)showHelperToolInfo:(id)sender;
{
	NSString *string =
		@"For GemStone/S 64 Bit to run properly, certain kernel settings may need be be adjusted: \n\n"
	
		"kern.sysv.shmmax and kern.sysv.shmall can be configured at boot time by editing \n"
			"\t'/etc/sysctl.conf' \n"
		"or set anytime by using 'sysctl' in a Terminal (though these changes will not be persistent). "
		"If the helper tool is installed we will temporarily set these values to the available RAM.\n\n"
	
		"If you click the 'Authenticate' button and provide authentication as an administrative user "
		"then we will use the SMJobBless() function to install\n"
			"\t'/Library/LaunchDaemons/com.GemTalk.GemStone.Helper.plist'\n"
		"and the tool as\n"
			"\t'/Library/PrivilegedHelperTools/com.GemTalk.GemStone.Helper'.\n"
		"These can be removed with the Remove button.";
	/*
	. If the helper tool is installed, we will set these automatically.\n"
		This can be done manually in a Terminal as follows:\n$ sudo sysctl -w kern.sysv.shmall=614400\n$ sudo sysctl -w kern.sysv.shmmax=2516582400\nAlternatively, we can install a \"helper tool\" that is managed by launchd and updates the kernel settings (if necessary) when starting a local database.\n\nIf you have manually configured the kernel settings (as above) then this should not be necessary. Also, if your only use of this application is to access databases running on another host, then you don't need to install the helper tool.\n\nIn any case, you may skip this step for now and we will ask for permission if the tool is needed.";
	 */
	[infoPanelTextView setString:string];
    [[NSApp mainWindow]beginSheet:infoPanel completionHandler:^(NSModalResponse returnCode) {
        return;
    }];
}

- (NSTableView *)statmonTableView;
{
	return statmonTableView;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
{
	if (tabViewItem == setupTabViewItem) {
		[self updateSetupState];
		return;
	}
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

- (void)taskError:(NSString *)aString;
{
	[self performSelectorOnMainThread:@selector(taskErrorA:) 
						   withObject:aString 
						waitUntilDone:NO];
}

- (void)taskErrorA:(NSString *)aString;
{
//	[operations cancelAllOperations];
	[self criticalAlert:@"Task Failed"
				details:aString];
	[self taskFinishedAfterDelay];
}

- (void)taskFinished;
{
	[self performSelectorOnMainThread:@selector(taskFinishedA)
						   withObject:nil
						waitUntilDone:NO];
}

- (void)taskFinishedA;
{
	[taskProgressText setString:[NSMutableString new]];
	[NSApp endSheet:taskProgressPanel];
	[taskProgressPanel orderOut:nil];
}

- (void)taskFinishedAfterDelay;
{
	[self performSelectorOnMainThread:@selector(taskFinishedAfterDelayA)
						   withObject:nil
						waitUntilDone:NO];
}

- (void)taskFinishedAfterDelayA;
{
	[taskProgressIndicator stopAnimation:self];
	[taskCancelButton setTitle:@"Close"];
	[self performSelector:@selector(taskFinishedAfterDelayB)
			   withObject:nil
			   afterDelay:1.0];
}

- (void)taskFinishedAfterDelayB;
{
	if ([[mySetup taskCloseWhenDoneCode] boolValue]) {
		[self taskFinishedA];
	}
}

- (void)taskProgress:(NSString *)aString;
{
	Boolean isVisible = [taskProgressPanel isVisible];
    NSUInteger length =[aString length];
	Boolean hasLength = 0 < length;
	if (isVisible && hasLength) {
		[self performSelectorOnMainThread:@selector(taskProgressA:)
							   withObject:aString
							waitUntilDone:YES];
	} else {
		NSLog(@"taskProgress: - %i %lu '%@'", isVisible, (unsigned long)length, aString);
	}
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
	[self doRunLoopFor:0.01];	//	ensure that it happens
}

- (void)taskStart:(NSString *)aString;
{
	[self performSelectorOnMainThread:@selector(taskStartA:) 
						   withObject:aString
						waitUntilDone:YES];
}

- (void)taskStartA:(NSString *)aString;
{
	if (![taskProgressPanel isVisible]) {
        [[NSApp mainWindow] beginSheet:taskProgressPanel
                     completionHandler:^(NSModalResponse returnCode) {
                         return;
                     }];
		[taskProgressIndicator setIndeterminate:YES];
		[taskProgressIndicator startAnimation:self];
		[taskCancelButton setTitle:@"Cancel"];
		[taskCloseWhenDoneButton setState:[[mySetup taskCloseWhenDoneCode] integerValue]];
	}
	[self taskProgressA:aString];
	[self doRunLoopFor:0.01];	//	ensure that it happens
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

- (void)updateSetupState;
{
	BOOL isAvailable = [helper isAvailable];
	[helperToolMessage setHidden:!isAvailable];
	[authenticateButton setEnabled:!isAvailable];
	[removeButton setEnabled:isAvailable];
	if (!isAvailable) {
		//	if helper tool needs to be installed, then ensure that Setup tab is selected
		[topTabView selectFirstTabViewItem:nil];
	}

	[currentShmall setStringValue:[helper shmall]];
	[currentShmmax setStringValue:[helper shmmax]];
	[hostname setStringValue:[helper hostName]];

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
		
		NSMutableArray *oldVersions = [NSMutableArray arrayWithArray:[versionListController arrangedObjects]];
		for (NSDictionary *dict in [download versions]) {
			Version *oldVersion = nil;
			for (Version *each in oldVersions) {
				if (!oldVersion && [[each name] isEqualToString:[dict objectForKey:@"name"]]) {
					oldVersion = each;
				}
			}
			if (oldVersion) {
				if (![oldVersion.date isEqualToDate:[dict objectForKey:@"date"]]) {
					oldVersion.date = [dict objectForKey:@"date"];
				}
				[oldVersions removeObject:oldVersion];
			} else {
				Version *version = [[Version alloc]
									initWithEntity:entity 
									insertIntoManagedObjectContext:managedObjectContext];
				[version setName:[dict objectForKey:@"name"]];
				[version setDate:[dict objectForKey:@"date"]];
				[versionListController addObject:version];
			}
		}
		//	remove versions that no longer exist
		for (Version *eachVersion in oldVersions) {
			if (![eachVersion isInstalled]) {
				if (![self databaseExistsForVersion:eachVersion]) {
					[versionListController removeObject:eachVersion];
					[managedObjectContext deleteObject:eachVersion];
				}
			}
		}
		[mySetup setVersionsDownloadDate:[NSDate date]];
		[versionListController rearrangeObjects];
		[self refreshInstalledVersionsList];
		[self refreshUpgradeVersionsList];
		[self taskProgressA:@"New version list received!"];
	}
	[self taskFinishedAfterDelay];
}

- (IBAction)versionListDownloadRequest:(id)sender;
{
	[appController taskStart:@"Obtaining GemStone/S 64 Bit version list ...\n"];
	DownloadVersionList *task = [DownloadVersionList new];
	__block Task *blockTask = task;
	[task setCompletionBlock:^(){
		[self performSelectorOnMainThread:@selector(versionListDownloadDone:) 
							   withObject:blockTask
							waitUntilDone:NO];
	}];
	[operations addOperation:task];
}

- (void)versionUnzipDone:(UnzipVersion *)unzipTask;
{
	if (![unzipTask isCancelled]) {
		NSManagedObjectModel *managedObjectModel = [[managedObjectContext persistentStoreCoordinator] managedObjectModel];
		NSString *path = [unzipTask zipFilePath];
		NSInteger lastSlash = -1, lastDash = -1;
		for (NSUInteger i = 0; i < [path length]; ++i) {
			char myChar = [path characterAtIndex:i];
			if (myChar == '/') lastSlash = i;
			if (myChar == '-') lastDash = i;
		}
		NSString *name = [[path substringToIndex:lastDash] substringFromIndex:lastSlash + 14];
		Boolean isVersionPresent = NO;
		for (Version *version in [versionListController arrangedObjects]) {
			isVersionPresent = isVersionPresent || [[version name] isEqualToString:name];
		}
		if (!isVersionPresent) {
			NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Version"];
			Version *version = [[Version alloc]
								initWithEntity:entity 
								insertIntoManagedObjectContext:managedObjectContext];
			[version setName:name];
			[version setDate:[NSDate date]];
			[versionListController addObject:version];
		}
		[self refreshInstalledVersionsList];
		[self refreshUpgradeVersionsList];
		[self taskProgressA:@"Finished import of zip file!"];
	}
	[self taskFinishedAfterDelay];
}

- (IBAction)versionUnzipRequest:(id)sender;
{
	[[UnzipVersion new] unzip];
}

- (BOOL)windowShouldClose:(NSWindow *)window;
{
    BOOL shouldWait = NO;
    for (id database in [databaseListController arrangedObjects]) {
        if ([database isRunning]) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"Yes"];
            [alert addButtonWithTitle:@"No"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:[NSString stringWithFormat:@"Stop %@?", [database name]]];
            [alert setInformativeText:@"Databases can continue to run without GemStone.app."];
            switch ( [alert runModal] ) {
                case NSAlertFirstButtonReturn:  // YES
                    [database stopDatabase];
                    shouldWait = YES;
                    break;
                    
                case NSAlertThirdButtonReturn:  // Cancel
                    return NO;
                    break;
                    
                default:
                    break;
            };
        }
    }
    if (shouldWait) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
            //Background Thread
            while (0 < [operations operationCount]) {
                [NSThread sleepForTimeInterval:0.1f];
            }
            [NSThread sleepForTimeInterval:2.0f];
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [window close];
            });
        });
        return NO;
    }
    return YES;
}

@end
