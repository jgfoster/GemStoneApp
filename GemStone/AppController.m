//
//  AppController.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import <ExceptionHandling/NSExceptionHandler.h>
#import <objc/runtime.h>

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

@interface NSManagedObject (Setup)
@property NSNumber *lastDatabaseIdentifier;
@property NSNumber *taskCloseWhenDoneCode;
@property NSDate   *versionsDownloadDate;
@end 

@interface AppController()
//	Setup Tab
@property (weak)	IBOutlet NSTabViewItem			*setupTabViewItem;
@property (weak)	IBOutlet NSTextField			*helperToolMessage;
@property (weak)	IBOutlet NSButton				*authenticateButton;
@property (weak)	IBOutlet NSTextField			*currentShmall;
@property (weak)	IBOutlet NSTextField			*currentShmmax;
@property (weak)	IBOutlet NSTextField			*hostname;
@property (weak)	IBOutlet NSTextField			*ipAddress;
@property (weak)	IBOutlet NSButton				*addToEtcHostsButton;
//	Versions Tab
@property (weak)	IBOutlet NSTextField			*lastUpdateDateField;
//	Databases Tab
@property (weak)    IBOutlet NSButton               *addDatabaseButton;
@property (weak)    IBOutlet NSButton               *deleteDatabaseButton;
@property (weak)	IBOutlet NSArrayController		*databaseListController;
@property (weak)	IBOutlet NSTableView			*databaseTableView;
@property (weak)	IBOutlet NSArrayController		*logFileListController;
@property (weak)	IBOutlet NSButton				*removeButton;
@property (weak)	IBOutlet NSArrayController		*versionListController;
@property (weak)	IBOutlet NSArrayController		*versionPopupController;
@property (weak)	IBOutlet NSArrayController		*upgradePopupController;
@property (weak)	IBOutlet NSTextField			*oldLogFilesText;
@property (weak)	IBOutlet NSButton				*deleteLogFilesButton;
@property (weak)	IBOutlet NSTextField			*oldTranLogsText;
@property (weak)	IBOutlet NSButton				*deleteTranLogsButton;
@property (weak)	IBOutlet NSArrayController		*dataFileListController;
@property			IBOutlet NSTextView				*dataFileInfo;
@property (weak)	IBOutlet NSTextField			*dataFileSizeText;
@property (weak)	IBOutlet NSArrayController		*processListController;
@property (weak)	IBOutlet NSTabViewItem			*gsListTabViewItem;
@property (weak)	IBOutlet NSTableView			*statmonTableView;
@property (weak)	IBOutlet NSObjectController		*statmonFileSelectedController;
@property (weak)	IBOutlet NSTabView				*topTabView;
@property (weak)	IBOutlet NSButton				*repositoryConversionCheckbox;
@property (weak)	IBOutlet NSButton				*upgradeSeasideCheckbox;

@property (weak)	IBOutlet NSPanel				*infoPanel;
@property           IBOutlet NSTextView             *infoPanelTextView;
@property (weak)	IBOutlet NSPanel				*taskProgressPanel;
@property			IBOutlet NSTextView				*taskProgressText;
@property (weak)	IBOutlet NSProgressIndicator	*taskProgressIndicator;
@property (weak)	IBOutlet NSButton				*taskCloseWhenDoneButton;
@property (weak)	IBOutlet NSButton				*taskCancelButton;

@property					Helper					*helper;
@property (readonly)		NSManagedObjectContext	*managedObjectContext;
@property					NSManagedObject			*mySetup;	//	'setup' is too common for searches!
@property					NSMutableDictionary		*statmonitors;
@property					NSOperationQueue		*operations;

@end

@implementation AppController

- (IBAction)addDatabase:(id)sender {
	NSManagedObjectModel *managedObjectModel = [[[self managedObjectContext] persistentStoreCoordinator] managedObjectModel];
	NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Database"];
	Database *database = [[Database alloc]
						initWithEntity:entity
						insertIntoManagedObjectContext:[self managedObjectContext]];
	[self.databaseListController addObject:database];
}

- (void)addOperation:(NSOperation *)anOperation {
	[self.operations addOperation:anOperation];
}

- (IBAction)addToEtcHosts:(id)sender {
	[self.helper addToEtcHosts];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
	self.helper = [Helper new];
	[self.taskProgressText setString:[NSMutableString new]];
	[self.taskProgressText setFont:[NSFont fontWithName:@"Monaco" size:9]];
	[self.statmonFileSelectedController setContent:[NSNumber numberWithBool:NO]];
	[self.repositoryConversionCheckbox setState:NSOffState];
	[self.upgradeSeasideCheckbox setState:NSOffState];
		
	[self.databaseListController addObserver:self
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
	
	[self reflectionTest];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	NSArray *list;
	list = [self.versionListController arrangedObjects];
	for (int i = 0; i < [list count]; ++i) {
		Version *version = [list objectAtIndex:i];
		if (version.indexInArray != [NSNumber numberWithInt:i]) {
			version.indexInArray = [NSNumber numberWithInt:i];
		}
	}
	list = [self.databaseListController arrangedObjects];
	for (int i = 0; i < [list count]; ++i) {
		Database *database = [list objectAtIndex:i];
		if (database.indexInArray != [NSNumber numberWithInt:i]) {
			database.indexInArray = [NSNumber numberWithInt:i];
		}
	}

	[self saveData];
    [self.helper terminate];
}

- (IBAction)cancelTask:(id)sender {
	if (0 < [self.operations operationCount]) {
		[self.operations cancelAllOperations];
		[self taskFinishedAfterDelay];
	} else {	//	Presumably this means that the title was changed to "Close"
        [self closeTaskProgressPanel];
	}
}

- (void)checkForSetupRequired {
	[self performSelectorOnMainThread:@selector(checkForSetupRequiredA)
						   withObject:nil
						waitUntilDone:YES];
}

- (void)checkForSetupRequiredA {
	if (0 == [[self versionList] count]) {
		[self.topTabView selectFirstTabViewItem:nil];
	}
}

- (IBAction)clickedDataFile:(id)sender {
	[self.dataFileInfo setString:@""];
	[self.dataFileSizeText setStringValue:@""];
	Database *database = [self selectedDatabase];
	if (!database) return;
	NSTableView *dataFileList = sender;
	NSArrayController *arrayController = (NSArrayController *)[dataFileList dataSource];
	NSInteger rowIndex = [dataFileList selectedRow];
	if (rowIndex < 0) return;
	NSString *file = [[arrayController arrangedObjects] objectAtIndex:rowIndex];
	[self.dataFileInfo setString:[database infoForDataFile:file]];
	[self.dataFileSizeText setStringValue:[database sizeForDataFile:file]];
}

- (IBAction)closeInfoPanel:(id)sender {
	[self.taskProgressText setString:[NSMutableString new]];
	dispatch_async(dispatch_get_main_queue(), ^{
        [[NSApp mainWindow] endSheet:self.infoPanel returnCode:0];
	});
}

- (void)closeTaskProgressPanel {
    [self.taskProgressText setString:[NSMutableString new]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSApp mainWindow] endSheet:self.taskProgressPanel returnCode:0];
    });
}

- (void)criticalAlert:(NSString *)textString details:(NSString *)detailsString {
	NSArray *args = [NSArray arrayWithObjects:textString, detailsString, nil];
	[self performSelectorOnMainThread:@selector(criticalAlertA:) withObject:args waitUntilDone:NO];
}

- (void)criticalAlertA:(NSArray *)args {
	NSString *textString = [args objectAtIndex:0];
	NSString *detailsString = [args objectAtIndex:1];
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSAlertStyleCritical];
	[alert setMessageText:textString];
	[alert setInformativeText:detailsString];
	[alert addButtonWithTitle:@"Dismiss"];
	[alert runModal];
}

- (Boolean)databaseExistsForVersion:(Version *)version {
	for (Database *eachDatabase in [self.databaseListController arrangedObjects]) {
		if ([[eachDatabase version] isEqualToString:[version name]]) {
			return YES;
		}
	}
	return false;
}

- (void)databaseStartDone:(Database *)aDatabase {
	[self updateDatabaseList:nil];
	[self.statmonTableView	performSelector:@selector(reloadData)			withObject:nil afterDelay:0.5];
	[self					performSelector:@selector(updateDatabaseList:)	withObject:nil afterDelay:1.0];
	[self taskFinishedAfterDelay];
}

- (void)databaseStopDone:(Database *)aDatabase {
	[self updateDatabaseList:nil];
	[self.statmonTableView	performSelector:@selector(reloadData)			withObject:nil afterDelay:0.5];
	[self taskFinishedAfterDelay];
}

- (IBAction)deleteStatmonFiles:(id)sender {
	Database *database = [self selectedDatabase];
	NSIndexSet *indexes = [self.statmonTableView selectedRowIndexes];
	[database deleteStatmonFilesAtIndexes:indexes];
}

- (void)doRunLoopFor:(double)seconds {
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds]];
}

- (IBAction)doUpgrade:(id)sender {
	Database *database = [self selectedDatabase];
	NSString *oldVersion = [database version];
	NSString *newVersion = [[self.upgradePopupController selectedObjects] objectAtIndex:0];
	BOOL needsConversion = [self.repositoryConversionCheckbox state];
	BOOL doSeasideUpgrade = [self.upgradeSeasideCheckbox state];
	NSLog(@"doUpgrade: from %@ to %@ with %i and %i", oldVersion, newVersion, needsConversion, doSeasideUpgrade);
}

- (void)ensureSharedMemory {
	[self.helper ensureSharedMemory];
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(NSUInteger)aMask {
	return YES;
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(NSUInteger)aMask {
	NSString *string = [NSString stringWithFormat:@"%@\n\nSee Console for details.", [exception reason]];
	[self criticalAlert:@"Internal Application Error!" details:string];
	[self taskFinishedAfterDelay];
	return YES;
}

- (id)init {
	if (self = [super init]) {
		[[Utilities new] setupGlobals:self];
		[self initManagedObjectContext];
		[self setupExceptionHandler];
		self.statmonitors = [NSMutableDictionary new];
		self.operations = [NSOperationQueue new];
		[self.operations setName:@"OperationQueue"];
	}
	return self;
}

- (void) initManagedObjectContext {
	_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc]
												 initWithManagedObjectModel: model];
    [[self managedObjectContext] setPersistentStoreCoordinator: coordinator];
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

- (IBAction)installHelperTool:(id)sender {
	[self.helper install];
}

- (void)loadRequestForDatabase {
	[self loadRequest:@"Database" toController:self.databaseListController];
	// We used to have default values in an accessor, but the accessor was removed
	for (Database *eachDatabase in [self.databaseListController arrangedObjects]) {
		[eachDatabase setDefaults];
	}
}

- (void)loadRequestForSetup {
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Setup" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:entity];
	NSError *error = nil;
	NSArray *list = [[self managedObjectContext] executeFetchRequest:request error:&error];
	if (!list || ![list count]) {
		self.mySetup = [NSEntityDescription insertNewObjectForEntityForName:@"Setup" inManagedObjectContext:[self managedObjectContext]];
	} else {
		self.mySetup = [list objectAtIndex:0];
	}
}

- (void)loadRequestForVersion {
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
	[self.versionListController setSortDescriptors:sortDescriptors];
	[self loadRequest:@"Version" toController:self.versionListController];
}

- (void)loadRequest:(NSString *)requestName toController:(NSArrayController *)controller {
	NSError *error = nil;
	
	NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:requestName];
	NSArray *list = [[self managedObjectContext] executeFetchRequest:request error:&error];
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

- (Database *)mostAdvancedDatabase {
	NSArray *databases = [self.databaseListController arrangedObjects];
	if (0 == [databases count]) return nil;
	Database *database = [databases objectAtIndex:0];
	for (Database *each in databases) {
		if ([[database version]compare:[each version]]== NSOrderedAscending) {
			database = each;
		}
	}
	return database;
}

- (NSString *)mostAdvancedVersion {
	NSString *name = nil;
	for (Version *each in [self versionList]) {
		if ([each isInstalled] && (name == nil || [name compare:each.name]== NSOrderedAscending)) {
			name = each.name;
		}
	}
	return name;
}

- (NSNumber *)nextDatabaseIdentifier {
	NSNumber *identifier = [self.mySetup lastDatabaseIdentifier];
	for (int i = 1; i < [identifier intValue]; ++i) {
		BOOL found = NO;
		for (Database *eachDatabase in [self.databaseListController arrangedObjects]) {
			if ([eachDatabase hasIdentifier] && [[eachDatabase identifier] intValue] == i) {
				found = YES;
				break;
			}
		}
		if (!found) {
			return [NSNumber numberWithInt:i];
		}
	}
	identifier = [NSNumber numberWithInt:[identifier intValue] + 1];
	[self.mySetup setLastDatabaseIdentifier:identifier];
	return identifier;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (object == self.databaseListController) {
		[self selectedDatabase:[self selectedDatabase]];
		return;
	}
	NSLog(@"keyPath = %@; object = %@; change = %@; context = %@", keyPath, object, change, context);
}

- (IBAction)openBrowserOnAvailableVersions:(id)sender {
	NSURL *url = [NSURL URLWithString:@"http://seaside.gemtalksystems.com/downloads/i386.Darwin/"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openDefaultConfigFile:(id)sender {
	[[self selectedDatabase] openDefaultConfigFile];

}

- (IBAction)openGemConfigFile:(id)sender {
	[[self selectedDatabase] openGemConfigFile];
}

- (IBAction)openStatmonFiles:(id)sender {
	NSIndexSet *indexes = [self.statmonTableView selectedRowIndexes];
	[[self selectedDatabase] openStatmonFilesAtIndexes:indexes];
}

- (IBAction)openStoneConfigFile:(id)sender {
	[[self selectedDatabase] openStoneConfigFile];
}

- (IBAction)openSystemConfigFile:(id)sender {
	[[self selectedDatabase] openSystemConfigFile];
}

- (NSString *)pathToDataFile {
	return [basePath stringByAppendingString:@"/data.binary"];
}

- (void)reflectionTest {
	/*
	const char *myName = class_getName([self.helper class]);
	size_t mySize = class_getInstanceSize([self.helper class]);
	unsigned int outCount;
	Ivar _Nonnull * ivarList = class_copyIvarList([self.helper class], &outCount);
	const char * iVarName1 = ivar_getName(ivarList[0]);
	const char * iVarType1 = ivar_getTypeEncoding(ivarList[0]);
	ptrdiff_t iVarOffset1 = ivar_getOffset(ivarList[0]);
	objc_property_t myProperty1 = class_getProperty([self.helper class], "hasDNS");
	Ivar myIvar1 = class_getInstanceVariable([self.helper class], "_hasDNS");
	objc_property_t myIvar2 = class_getProperty([self.helper class], "ipAddress");
	objc_property_t myIvar3 = class_getProperty([self.helper class], "isAvailable");
	objc_property_t myIvar4 = class_getProperty([self.helper class], "connection");
	*/

}
- (IBAction)removeDatabase:(id)sender {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:@"Are you sure?"];
	[alert setInformativeText:@"This will delete the database and all configuration information!"];
	[alert addButtonWithTitle:@"Delete"];
	[alert addButtonWithTitle:@"Cancel"];
	if ([alert runModal] == NSAlertSecondButtonReturn) return;
	NSArray *list = [self.databaseListController selectedObjects];
	Database *database = [list objectAtIndex:0];
	if ([database isRunning]) {
		[database stopDatabase];
		while ([self.taskProgressPanel isKeyWindow]) {
			[self doRunLoopFor:0.1];
		}
	}
	[database deleteAll];
	[self.databaseListController remove:sender];
	[[self managedObjectContext] deleteObject:database];
	[self saveData];
}

- (IBAction)removeHelperTool:(id)sender {
	[self.helper remove];
}

- (void)removeVersionDone {
	[self refreshInstalledVersionsList];
	[self refreshUpgradeVersionsList];
	[self taskProgress:@" . . . Done!"];
	[self taskFinishedAfterDelay];
}

- (void)refreshInstalledVersionsList {
    Boolean hasAnyInstalledVersions = false;
	[self.versionPopupController removeObjects:[self.versionPopupController arrangedObjects]];
	for (Version *version in [self.versionListController arrangedObjects]) {
		[version updateIsInstalled];
		if ([version isInstalled]) {
			[self.versionPopupController addObject:[version name]];
            hasAnyInstalledVersions = true;
		}
	}
	[self.lastUpdateDateField setObjectValue:[self.mySetup versionsDownloadDate]];
    [self.addDatabaseButton setEnabled:hasAnyInstalledVersions];
}

- (void)refreshUpgradeVersionsList {
	Database *database = [self selectedDatabase];
	[self.upgradePopupController removeObjects:[self.upgradePopupController arrangedObjects]];
	if (database) {
		NSString *currentVersion = [database version];
		for (Version *version in [self.versionListController arrangedObjects]) {
			NSString *name = [version name];
			if ([version isInstalled] && [currentVersion compare:name] == NSOrderedAscending) {
				[self.upgradePopupController addObject:name];
			}
		}
	}
}

- (void)saveData {
	BOOL hasChanges = [[self managedObjectContext] hasChanges];
	if (!hasChanges) { return; }
	
	NSError *error = nil;
	BOOL saveWasSuccessful = [[self managedObjectContext] save:&error];
	if (!saveWasSuccessful) {
		NSString *myString = [error localizedDescription] != nil ? [error localizedDescription] : @"Unknown Error";
        AppError(@"Data save failed\n%@",myString);
	}
}

- (Database *)selectedDatabase {
	NSArray *list = [self.databaseListController selectedObjects];
	Database *database = nil;
	if (0 < [list count]) {
		database = [list objectAtIndex:0];
	}
	return database;
}

- (void)selectedDatabase:(Database *)aDatabase {
	[self.logFileListController removeObjects:[self.logFileListController arrangedObjects]];
	[self.dataFileListController removeObjects:[self.dataFileListController arrangedObjects]];
	[self.statmonTableView setDataSource:nil];
	[self.statmonTableView setDelegate:nil];
	[self.statmonTableView setTarget:nil];
	[self.oldLogFilesText setStringValue:@""];
	[self.oldTranLogsText setStringValue:@""];
	[self.dataFileInfo setString:@""];
	if (aDatabase == nil) return;
	[aDatabase createConfigFiles];
	[aDatabase refreshStatmonFiles];
	[self.logFileListController addObjects:[aDatabase logFiles]];
	[self.oldLogFilesText setStringValue:[aDatabase descriptionOfOldLogFiles]];
	[self.oldTranLogsText setStringValue:[aDatabase descriptionOfOldTranLogs]];
	[self.dataFileListController addObjects:[aDatabase dataFiles]];
	[self.statmonTableView setDataSource:aDatabase];
	[self.statmonTableView setDelegate:aDatabase];
	[self.statmonTableView setTarget:aDatabase];
	[self.statmonTableView setDoubleAction:@selector(doubleClickStatmon:)];
	[self.statmonTableView reloadData];
	[self refreshUpgradeVersionsList];
	[self.repositoryConversionCheckbox setState:NSOffState];
	[self.upgradeSeasideCheckbox setState:NSOffState];
}

- (void)setIsStatmonFileSelected:(BOOL)flag {
	[self.statmonFileSelectedController setContent:[NSNumber numberWithBool:flag]];
}

- (void)setupExceptionHandler {
	NSExceptionHandler *handler = [NSExceptionHandler defaultExceptionHandler];
	[handler setExceptionHandlingMask:[handler exceptionHandlingMask] | NSLogOtherExceptionMask];
	[handler setDelegate:self];
}

- (IBAction)showHelperToolInfo:(id)sender {
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
		"These can be removed with the Remove button.\n\n"
	
		"The local host needs to be reachable on the network. If the IP Address is unknown, then "
		"you can enable File Sharing in System Preferences or add the hostname to /etc/hosts.\n\n"
	
		"";
	[self.infoPanelTextView setString:string];
    [[NSApp mainWindow]beginSheet:self.infoPanel completionHandler:^(NSModalResponse returnCode) {
        [self.infoPanel orderOut:self];
    }];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	if (tabViewItem == self.setupTabViewItem) {
		[self.helper checkDNS];
		[self updateSetupState];
	} else if (tabViewItem == self.gsListTabViewItem) {
		[self updateDatabaseState];
	}
}

- (IBAction)taskCloseWhenDone:(id)sender {
	NSButton *myButton = sender;
	NSInteger state = [myButton state];
	[self.mySetup setTaskCloseWhenDoneCode:[NSNumber numberWithInteger:state]];
}

- (void)taskError:(NSString *)aString {
	[self performSelectorOnMainThread:@selector(taskErrorA:) 
						   withObject:aString 
						waitUntilDone:NO];
}

- (void)taskErrorA:(NSString *)aString {
//	[operations cancelAllOperations];
//    [operations cancelAllOperations];
	[self criticalAlert:@"Task Failed"
				details:aString];
	[self taskFinishedAfterDelay];
}

- (void)taskFinishedAfterDelay {
	[self performSelectorOnMainThread:@selector(taskFinishedAfterDelayA)
						   withObject:nil
						waitUntilDone:NO];
}

- (void)taskFinishedAfterDelayA {
	[self.taskProgressIndicator stopAnimation:self];
	[self.taskCancelButton setTitle:@"Close"];
	[self performSelector:@selector(taskFinishedAfterDelayB)
			   withObject:nil
			   afterDelay:1.0];
}

- (void)taskFinishedAfterDelayB {
	if ([[self.mySetup taskCloseWhenDoneCode] boolValue]) {
        [self closeTaskProgressPanel];
	}
}

- (void)taskProgress:(NSString *)aString {
    NSUInteger length = [aString length];
	Boolean hasLength = 0 < length;
	if (hasLength) {
		[self performSelectorOnMainThread:@selector(taskProgressA:)
							   withObject:aString
							waitUntilDone:YES];
	} else {
		NSLog(@"taskProgress: \"\"");
	}
}

- (void)taskProgressA:(NSString *)aString {
    if (![self.taskProgressPanel isVisible]) return;
	NSArray *array = [aString componentsSeparatedByString:@"\r"];
	NSRange range = {self.taskProgressText.string.length, 0};
	[self.taskProgressText insertText:[array objectAtIndex:0] replacementRange:range];
	for (int i = 1; i < [array count]; ++i) {
		NSString *string = [self.taskProgressText string];
		NSString *nextLine = [array objectAtIndex:i];
		int lastLF = -1;
		for (int j = 0; j < [string length]; ++j) {
			if (10 == [string characterAtIndex:j]) {
				lastLF = j;
			}
		}
		if (0 < lastLF) {
			range = NSMakeRange(lastLF + 1, [string length] - 1);
			[self.taskProgressText setSelectedRange:range];
			double value = [nextLine doubleValue];
			if (value) {
				[self.taskProgressIndicator setIndeterminate:NO];
				[self.taskProgressIndicator setDoubleValue:value];
			}
		} else {
			range = NSMakeRange(self.taskProgressText.string.length, 0);
		}
		[self.taskProgressText insertText:nextLine replacementRange:range];
	}
	[self doRunLoopFor:0.01];	//	ensure that it happens
}

- (void)taskStart:(NSString *)aString {
	[self performSelectorOnMainThread:@selector(taskStartA:)
						   withObject:aString
						waitUntilDone:YES];
}

- (void)taskStartA:(NSString *)aString {
	if (![self.taskProgressPanel isVisible]) {
        [[NSApp mainWindow] beginSheet:self.taskProgressPanel
                     completionHandler:^(NSModalResponse returnCode) {
                         [self.taskProgressPanel orderOut:self];
                     }];
		[self.taskProgressIndicator setIndeterminate:YES];
		[self.taskProgressIndicator startAnimation:self];
		[self.taskCancelButton setTitle:@"Cancel"];
		[self.taskCloseWhenDoneButton setState:[[self.mySetup taskCloseWhenDoneCode] integerValue]];
	}
	[self taskProgressA:aString];
	[self doRunLoopFor:0.01];	//	ensure that it happens
}

- (void)updateDatabaseList:(id)sender {
	NSUInteger index = [self.databaseListController selectionIndex];
	[self.databaseListController setAvoidsEmptySelection:NO];
	[self.databaseListController setSelectedObjects:[NSArray new]];
	[self.databaseListController setSelectionIndex:index];
	[self.databaseListController setAvoidsEmptySelection:YES];
}

- (void)updateDatabaseState {
	Database *database = [self mostAdvancedDatabase];
	if (!database) return;
	[self performSelectorInBackground:@selector(_updateDatabaseState:) withObject:database];
}

- (void)_updateDatabaseState:(Database *)database {
	NSArray *list = [GSList processListUsingDatabase:database];
	[self performSelectorOnMainThread:@selector(updateDatabaseState:) withObject:list waitUntilDone:NO];
}

- (void)updateDatabaseState:(NSArray *)list {
	Database *database;
	for (database in [self.databaseListController arrangedObjects]) {
		[database gsList:list];
	}
	[self.processListController removeObjects:[self.processListController arrangedObjects]];
	[self.processListController addObjects:list];
	[self.databaseTableView reloadData];
}

- (void)updateSetupState {
	BOOL isAvailable = [self.helper isAvailable];
	[self.helperToolMessage setHidden:!isAvailable];
	[self.authenticateButton setEnabled:!isAvailable];
	[self.removeButton setEnabled:isAvailable];
	if (!isAvailable) {
		//	if helper tool needs to be installed, then ensure that Setup tab is selected
		[self.topTabView selectFirstTabViewItem:nil];
	}

	[self.currentShmall setStringValue:[self.helper shmall]];
	[self.currentShmmax setStringValue:[self.helper shmmax]];
	[self.hostname setStringValue:[self.helper hostName]];
	if ([self.helper hasDNS]) {
		[self.ipAddress setStringValue:[self.helper ipAddress]];
		[self.addToEtcHostsButton setEnabled:NO];
	} else {
		[self.ipAddress setStringValue:@"-unknown-"];
		[self.addToEtcHostsButton setEnabled:isAvailable];
	}
}

- (NSArray *)versionList {
	return [self.versionListController arrangedObjects];
}

- (void)versionListDownloadDone:(DownloadVersionList *)download {
	if (![download isCancelled]) {
		NSManagedObjectModel *managedObjectModel = [[[self managedObjectContext] persistentStoreCoordinator] managedObjectModel];
		NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Version"];
		
		NSMutableArray *oldVersions = [NSMutableArray arrayWithArray:[self.versionListController arrangedObjects]];
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
									insertIntoManagedObjectContext:[self managedObjectContext]];
				[version setName:[dict objectForKey:@"name"]];
				[version setDate:[dict objectForKey:@"date"]];
				[self.versionListController addObject:version];
			}
		}
		//	remove versions that no longer exist
		for (Version *eachVersion in oldVersions) {
			if (![eachVersion isInstalled]) {
				if (![self databaseExistsForVersion:eachVersion]) {
					[self.versionListController removeObject:eachVersion];
					[[self managedObjectContext] deleteObject:eachVersion];
				}
			}
		}
		[self.mySetup setVersionsDownloadDate:[NSDate date]];
		[self.versionListController rearrangeObjects];
		[self refreshInstalledVersionsList];
		[self refreshUpgradeVersionsList];
		[self taskProgressA:@"New version list received!"];
	}
	[self taskFinishedAfterDelay];
}

- (IBAction)versionListDownloadRequest:(id)sender {
	[appController taskStart:@"Obtaining GemStone/S 64 Bit version list ...\n"];
	DownloadVersionList *task = [DownloadVersionList new];
	//	https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Blocks/Articles/bxVariables.html#//apple_ref/doc/uid/TP40007502-CH6-SW1
	__block Task *blockTask = task;		//	blocks get a COPY of referenced objects unless explicitly shared
	[task setCompletionBlock:^(){
		[self performSelectorOnMainThread:@selector(versionListDownloadDone:) 
							   withObject:blockTask
							waitUntilDone:NO];
		blockTask = nil;				//	break reference count cycle
	}];
	[self.operations addOperation:task];
}

- (void)versionUnzipDone:(UnzipVersion *)unzipTask {
	if (![unzipTask isCancelled]) {
		NSManagedObjectModel *managedObjectModel = [[[self managedObjectContext] persistentStoreCoordinator] managedObjectModel];
		NSString *path = [unzipTask zipFilePath];
		NSInteger lastSlash = -1, lastDash = -1;
		for (NSUInteger i = 0; i < [path length]; ++i) {
			char myChar = [path characterAtIndex:i];
			if (myChar == '/') lastSlash = i;
			if (myChar == '-') lastDash = i;
		}
		NSString *name = [[path substringToIndex:lastDash] substringFromIndex:lastSlash + 14];
		Boolean isVersionPresent = NO;
		for (Version *version in [self.versionListController arrangedObjects]) {
			isVersionPresent = isVersionPresent || [[version name] isEqualToString:name];
		}
		if (!isVersionPresent) {
			NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Version"];
			Version *version = [[Version alloc]
								initWithEntity:entity 
								insertIntoManagedObjectContext:[self managedObjectContext]];
			[version setName:name];
			[version setDate:[NSDate date]];
			[self.versionListController addObject:version];
		}
		[self refreshInstalledVersionsList];
		[self refreshUpgradeVersionsList];
		[self taskProgressA:@"Finished import of zip file!"];
	}
	[self taskFinishedAfterDelay];
}

- (IBAction)versionUnzipRequest:(id)sender {
	[[UnzipVersion new] unzip];
}

- (BOOL)windowShouldClose:(NSWindow *)window;
{
    BOOL shouldWait = NO;
    for (id database in [self.databaseListController arrangedObjects]) {
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
            while (0 < [self.operations operationCount]) {
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
