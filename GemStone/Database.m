//
//  Database.m
//  GemStone
//
//  Created by James Foster on 5/17/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "AppController.h"
#import "CopyDBF.h"
#import "Database.h"
#import "GSList.h"
#import "Helper.h"
#import "LogFile.h"
#import "Login.h"
#import "Utilities.h"
#import "StartCacheWarmer.h"
#import "StartNetLDI.h"
#import "StartStone.h"
#import "Statmonitor.h"
#import "StopNetLDI.h"
#import "StopStone.h"
#import "Topaz.h"
#import "Utilities.h"
#import "Version.h"
#import "VSD.h"
#import "WaitStone.h"

@implementation Database

// following are part of the DataModel handled by Core Data
@dynamic indexInArray;
@dynamic lastStartDate;
@dynamic name;
@dynamic netLDI;
@dynamic spc_mb;
@dynamic version;

@synthesize isRunningCode;

- (void)archiveCurrentLogFiles;
{
	NSError  *error = nil;
	NSString *path = [NSString stringWithFormat:@"%@/log", [self directory]];
	NSArray  *baseList = [[self name] componentsSeparatedByString:@"_"];
	NSUInteger baseListCount = [baseList count];
	
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSArray *thisList = [file componentsSeparatedByString:@"_"];
		int j = -1;
		for (int i = 0; i == j + 1 && i < [thisList count] && i < baseListCount; ++i) {
			if (NSOrderedSame == [[baseList objectAtIndex:i] compare:[thisList objectAtIndex:i]]) {
				j = i;
			}
		}
		if (j + 1 == baseListCount) {
			NSString *target = [NSString stringWithFormat:@"%@/archive/%@", path, file];
			[fileManager removeItemAtPath:target error:nil];
			if (![fileManager 
				  moveItemAtPath:[NSString stringWithFormat:@"%@/%@", path, file]
				  toPath:target
				  error:&error]) {
				AppError(@"Unable to move %@/%@ because %@", path, file, [error description]);
			}
		}
	}
}

- (void)archiveCurrentTransactionLogs;
{
	NSError *error = nil;
	NSString *dataPath = [NSString stringWithFormat:@"%@/data", [self directory]];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:dataPath];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSRange first = [file rangeOfString:@"tranlog"];
		NSRange last  = [file rangeOfString:@".dbf"];
		if (first.location == 0 && first.length == 7 && last.location == [file length] - 4) {
			NSString *source = [NSString stringWithFormat:@"%@/%@", dataPath, file];
			NSString *target = [NSString stringWithFormat:@"%@/archive/%@", dataPath, file];
			[fileManager removeItemAtPath:target error:nil];
			if (![fileManager moveItemAtPath:source toPath:target error:&error]) {
				AppError(@"Unable to move %@ because %@", source, [error description]);
			}
		}
	}
}

- (void)backup;
{
	//	get path to backup
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setAllowedFileTypes:[NSArray arrayWithObjects:@"bak",@"gz", nil]];
	[panel setTitle:@"Create From a Full Backup"];
	[panel setMessage:@"Name of on-line backup:"];
	[panel setNameFieldStringValue:[NSString stringWithFormat:@"%@.bak.gz",[self name]]];
	[panel setExtensionHidden:NO];
	[panel setPrompt:@"Backup"];
	NSInteger result = [panel runModal];
    if (result != NSOKButton) return;
	
	NSString *path = [[panel URL] path];
	Login *login = [self defaultLogin];
	Topaz *topaz = [Topaz login:login 
					   toDatabase:self 
							andDo: ^(Topaz *aTopaz){ [aTopaz fullBackupTo:path]; }];
	[appController addOperation:topaz];
}

- (void)createConfigFile;
{
	NSString *directory = [self directory];
	NSString *path = [NSString stringWithFormat:@"%@/conf/system.conf", directory];
	NSMutableString *string = [NSMutableString new];
	[string appendFormat: @"DBF_EXTENT_NAMES = \"%@/data/extent0.dbf\";\n", directory];
	[string appendString: @"STN_TRAN_FULL_LOGGING = TRUE;\n"];
	[string appendFormat: @"STN_TRAN_LOG_DIRECTORIES = \"%@/data/\", \n", directory];
	[string appendFormat: @"	\"%@/data/\";\n", [self directory]];
	[string appendString: @"STN_TRAN_LOG_SIZES = 100, 100;\n"];
	[string appendString: @"KEYFILE = \"$GEMSTONE/seaside/etc/gemstone.key\";\n"];
	[string appendFormat: @"SHR_PAGE_CACHE_SIZE_KB = %lu;\n", [self spc_kb]];
	if (![fileManager 
			createFileAtPath:path 
			contents:[string dataUsingEncoding:NSUTF8StringEncoding] 
			attributes:nil]) {
		AppError(@"Unable to create config file at %@", path);
	};
}

- (void)createDirectories;
{
	[self createDirectory:@"conf"];
	[self createDirectory:@"data"];
	[self createDirectory:@"data/archive"];
	[self createDirectory:@"log"];
	[self createDirectory:@"log/archive"];
	[self createDirectory:@"stat"];
	[self createLocksDirectory];
}

- (void)createDirectory:(NSString *)aString;
{
	NSString *path = [NSString stringWithFormat:@"%@/%@", [self directory], aString];
	NSError *error = nil;
	if ([fileManager
		 createDirectoryAtPath:path
		 withIntermediateDirectories:YES
		 attributes:nil
		 error:&error]) return;
	AppError(@"Unable to create %@ because %@!", path, [error description]);
}

- (void)createLocksDirectory;
{
	NSError *error;
	// this needs to point to something
	NSString *localLink = [NSString stringWithFormat:@"%@/locks", [self directory]];
	// previous installations might have created this directory
	NSString *traditional = @"/opt/gemstone/locks";
	// if traditional path is not present, we will use application support directory
	NSString *alternate = [NSString stringWithFormat:@"%@/locks", basePath];
	
	// try linking to traditional location
	BOOL isDirectory;
	BOOL exists = [fileManager
				   fileExistsAtPath:traditional 
				   isDirectory:&isDirectory];
	if (exists && isDirectory) {
		if ([fileManager
			 createSymbolicLinkAtPath:localLink 
			 withDestinationPath:traditional 
			 error:&error]) return;
		AppError(@"unable to link %@ to %@ because %@", localLink, traditional, [error description]);
	};
	
	// try linking alternate location
	exists = [fileManager
			  fileExistsAtPath:alternate 
			  isDirectory:&isDirectory];
	if (exists && !isDirectory) {
		AppError(@"%@ is not a directory!", alternate);
	}
	if (!exists) {
		if (![fileManager
			 createDirectoryAtPath:alternate
			 withIntermediateDirectories:YES
			 attributes:nil
			 error:&error]) {
			AppError(@"unable to create %@ because %@", alternate, [error description]);
		}
	}
	if ([fileManager
		 createSymbolicLinkAtPath:localLink
		 withDestinationPath:alternate
		 error:&error]) return;
	AppError(@"unable to link %@ to %@ because %@", localLink, alternate, [error description]);
}

- (NSArray *)dataFiles;
{
	NSString *path = [NSString stringWithFormat:@"%@/data", [self directory]];
	NSError *error = nil;
	NSArray *fullList = [fileManager contentsOfDirectoryAtPath:path error:&error];
	if (!fullList) {
		AppError(@"Unable to get contents of %@ because %@", path, [error description]);
	}
	NSMutableArray *list = [NSMutableArray arrayWithCapacity:[fullList count]];
	for (NSString *each in fullList) {
		if ([each compare:@"archive"] != NSOrderedSame) {
			[list addObject:each];
		}
	}
	return list;
}

- (Login *)defaultLogin;
{
	NSManagedObjectContext *moc = [appController managedObjectContext];
	NSManagedObjectModel *managedObjectModel = [[moc persistentStoreCoordinator] 
												managedObjectModel];
	NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"Login"];
	Login *login = [[Login alloc]
					initWithEntity:entity
					insertIntoManagedObjectContext:moc];
	[login initializeForDatabase:self];
	return login;
}

- (void)deleteAll;
{
	NSString *path = [self directory];
	NSError *error = nil;
	if ([fileManager removeItemAtPath:path error:&error]) return;
	AppError(@"Unable to delete %@ because %@", path, [error description]);
}

- (void)deleteFilesIn:(NSString *)aString;
{
	NSString *path = [NSString stringWithFormat:@"%@/%@", [self directory], aString];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSError  *error = nil;
		NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, file];
		if (![fileManager removeItemAtPath:fullPath error:&error]) {
			AppError(@"unable to delete %@ because %@", fullPath, [error description]);
		};
	}
	[appController updateDatabaseList:nil];
}

- (void)deleteOldLogFiles;
{
	[self deleteFilesIn:@"log/archive"];
}

- (void)deleteOldTranLogs;
{
	[self deleteFilesIn:@"data/archive"];
}

- (void)deleteStatmonFilesAtIndexes:(NSIndexSet *)indexes;
{
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		NSDictionary *statmon = [[self statmonFiles] objectAtIndex:idx];
		NSError *error = nil;
		NSString *path = [statmon objectForKey:@"path"];
		if (![fileManager removeItemAtPath:path error:&error]) {
			AppError(@"Unable to delete %@ because %@", path, [error description]);
		}
	}];
	statmonFiles = nil;
	[[appController statmonTableView] reloadData];
}

- (NSString *)descriptionOfFilesIn:(NSString *)aString;
{
	NSString *path = [NSString stringWithFormat:@"%@/%@/archive", [self directory], aString];
	NSUInteger count = 0;
	NSUInteger size = 0;
	
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSError  *error = nil;
		NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, file];
		NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPath error:&error];
		if (error) {
			AppError(@"Unable to obtain attributes of %@ because %@", fullPath, [error description]);
		}
		count = count + 1;
		size = size + [[attributes valueForKey:NSFileSize] unsignedLongValue];
	}
	NSUInteger kbSize = size / 1024;
	NSUInteger mbSize = kbSize / 1024;
	return 9 < mbSize ?
		[NSString stringWithFormat:@"%lu files, %lu MB", count, mbSize] :
		[NSString stringWithFormat:@"%lu files, %lu KB", count, kbSize];
}

- (NSString *)descriptionOfOldLogFiles;
{
	return [self descriptionOfFilesIn:@"log"];
}
- (NSString *)descriptionOfOldTranLogs;
{
	return [self descriptionOfFilesIn:@"data"];
}

- (NSString *)directory;
{
	return [NSString stringWithFormat: @"%@/db%@", basePath, [self identifier]];
}

- (void)doubleClickStatmon:(id)sender;
{
	[self openStatmonFilesAtIndexes:[NSIndexSet indexSetWithIndex:[sender clickedRow]]];
}

- (NSString *)gemstone;
{
	NSString *path = [NSString stringWithFormat: @"%@/GemStone64Bit%@-i386.Darwin", basePath, [self version]];
	return path;
}

- (NSString *)gemToolsLogin;
{
	NSString *string = [NSString stringWithFormat:
@"Copy the following and use it to define a new session in the GemTools Launcher:\n\n"
"OGStandardSessionDescription new\n"
	"\tname: \'%@\';\n"
	"\tstoneHost: \'localhost\';\n"
	"\tstoneName: \'%@\';\n"
	"\tgemHost: \'localhost\';\n"
	"\tnetLDI: \'%@\';\n"
	"\tuserId: \'DataCurator\';\n"
	"\tpassword: \'swordfish\';\n"
	"\tbackupDirectory: \'\';\n"
	"\tyourself.\n", 
	[self name], [self name], [self netLDI]];
	return string;
}

- (void)gsList:(NSArray *)list;
{
	isRunningCode = [NSNumber numberWithBool:NO];
	for (NSDictionary *process in list) {
		NSString *string = [process valueForKey:@"version"];
		if ([string compare:version] == NSOrderedSame) {
			string = [process valueForKey:@"GEMSTONE"];
			if ([string compare:[self gemstone]] == NSOrderedSame) {
				string = [process valueForKey:@"logfile"];
				NSString *directory = [self directory];
				NSRange range = [string rangeOfString:directory];
				if (range.location == 0) {
					string = [process valueForKey:@"type"];
					if ([string compare:@"Stone"] == NSOrderedSame) {
						isRunningCode = [NSNumber numberWithBool:YES];
						return;
					}
				}
			}
		}
	}
}

- (NSNumber *)identifier;
{
	if (![identifier intValue]) {
		identifier = [appController nextDatabaseIdentifier];
		[self createDirectories];
		version = [appController mostAdvancedVersion];
		[self installBaseExtent];
	}
	return identifier;
}

- (NSString *)infoForDataFile:(NSString *)file;
{
	return [CopyDBF infoForFile:file in:self];
}

- (void)installBaseExtent;
{
	[self installExtent:@"extent0.dbf"];
}

- (void)installExtent: (NSString *) aString;
{
	NSError *error = nil;
	NSString *target = [NSString stringWithFormat:@"%@/data/extent0.dbf", [self directory]];
	if ([fileManager fileExistsAtPath:target]) {
		if (lastStartDate) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setAlertStyle:NSCriticalAlertStyle];
			[alert setMessageText:@"Replace existing repository?"];
			[alert setInformativeText:@"All data in the existing repository will be lost!"];
			[alert addButtonWithTitle:@"Cancel"];
			[alert addButtonWithTitle:@"Replace"];
			NSInteger answer = [alert runModal];
			if (NSAlertSecondButtonReturn != answer) {
				return;
			}
		}
		if (![fileManager removeItemAtPath:target error:&error]) {
			AppError(@"unable to delete %@ because %@", target, [error description]);
		}
	}
	[appController taskStart:[NSString stringWithFormat:@"Copying %@/bin/%@ . . .", [self gemstone], aString]];
	[self archiveCurrentTransactionLogs];
	NSString *source = [NSString stringWithFormat:@"%@/bin/%@", [self gemstone], aString];
	BOOL success = [fileManager copyItemAtPath:source toPath:target error:&error];
	if (!success) {
		AppError(@"copy from %@ to %@ failed because %@!", source, target, [error description]);
	}
	NSDictionary *attributes = [NSDictionary 
								dictionaryWithObject:[NSNumber numberWithInt:0600] 
								forKey:NSFilePosixPermissions];
	success = [fileManager setAttributes:attributes ofItemAtPath:target error:&error];
	if (!success) {
		AppError(@"Unable to change permissions of %@ because %@", target, [error description]);
	}
	lastStartDate = nil;
	[appController taskFinishedAfterDelay];
	[appController updateDatabaseList:nil];
}

- (void)installGlassExtent;
{
	[self installExtent:@"extent0.seaside.dbf"];
}

- (BOOL)isRunning;
{
	return [isRunningCode boolValue];
}

- (NSString *)isRunningString;
{
	return [self isRunning] ? @"yes" : @"no";
}

- (NSArray *)logFiles;
{
	NSMutableArray *list = [NSMutableArray array];
	NSString *path = [NSString stringWithFormat:@"%@/log", [self directory]];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		if (1 < [[file pathComponents] count]) {
			[dirEnum skipDescendents];
			continue;
		}
		if (NSOrderedSame == [@".log" compare:[file substringFromIndex:[file length]-4]]) {
			NSError *error = nil;
			NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, file];
			NSDictionary *dict = [fileManager attributesOfItemAtPath:fullPath error:&error];
			if (error) {
				AppError(@"Unable to obtain attributes of %@ because %@", fullPath, [error description]);
			}
			NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:dict];
			[attributes setValue:file forKey:@"name"];
			[attributes setValue:fullPath forKey:@"path"];
			[attributes setValue:[self name] forKey:@"stone"];
			[list addObject:[LogFile logFileFromDictionary:attributes]];
		}
	}
	return list;
}

- (NSString *)name;
{
	if ([name length]) return name;
	return [NSString stringWithFormat:@"gs64stone%@", [self identifier]];
}

- (NSString *)netLDI;
{
	if ([netLDI length]) return netLDI;
	return [NSString stringWithFormat:@"netldi%@", [self identifier]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
{
	if ([appController statmonTableView] == aTableView) {
		return [[self statmonFiles] count];
	}
	return 0;
}

- (void)open;
{
	[[NSWorkspace sharedWorkspace] openFile:[self directory]];
}

- (void)openStatmonFilesAtIndexes:(NSIndexSet *)indexes;
{
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		NSDictionary *statmon = [[self statmonFiles] objectAtIndex:idx];
		NSString *path = [statmon objectForKey:@"path"];
		[VSD openPath:path usingDatabase:self];
	}];
}

- (void)refreshStatmonFiles;
{
	statmonFiles = nil;
}

- (void)restore;
{
	//	get path to backup
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowedFileTypes:[NSArray arrayWithObjects:@"bak",@"gz", nil]];
	[panel setTitle:@"Restore From a Full Backup"];
	[panel setMessage:@"Select an on-line backup:"];
	[panel setPrompt:@"Restore"];
	NSInteger result = [panel runModal];
    if (result != NSOKButton) return;
	
	NSString	*path = [[[panel URLs] objectAtIndex:0] path];
	[self startDatabaseWithArgs:[NSArray arrayWithObject:@"-R"]];	//	defines statmonitor, but does not add it as an operation
	Login *login = [self defaultLogin];
	Topaz *topaz = [Topaz login:login 
					 toDatabase:self 
						  andDo:^(Topaz *aTopaz) {
							  [aTopaz restoreFromBackup:path]; }
					];
	[topaz addDependency:statmonitor];
	__block id me = self;
	[topaz setCompletionBlock:^(){
		[me startIsDone];
	}];
	[appController addOperation:statmonitor];
	[appController addOperation:topaz];
}

- (void)setIsRunning:(BOOL)aBool;
{
	isRunningCode = [NSNumber numberWithBool:aBool];
	if (aBool) {
		lastStartDate = [NSDate date];
	}
}

- (void)setVersion:(NSString *)aString;
{
	if (version == aString) return;
	version = aString;
	[self installBaseExtent];
}

- (NSString *)sizeForDataFile:(NSString *)file;
{
	NSString *path = [NSString stringWithFormat:@"%@/data/%@", [self directory], file];
	NSError *error = nil;
	NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
	if (error) {
		AppError(@"Unable to obtain attributes of %@ because %@", path, [error description]);
	}
	NSUInteger size = [[attributes valueForKey:NSFileSize] unsignedLongValue];
	NSString *units = @"bytes";
	if (10 * 1024 * 1024 < size) {
		size = size / 1024 / 1024;
		units = @"MB";
	} else if (10 * 1024 < size) {
		size = size / 1024;
		units = @"KB";
	}
	NSNumberFormatter *formatter = [NSNumberFormatter new];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];
	[formatter setGroupingSeparator: [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator]];
	NSString *formatted = [formatter stringFromNumber:[NSNumber numberWithInteger:size]];
	return [NSString stringWithFormat:@"%@ %@", formatted, units];
}

- (unsigned long)spc_kb;
{
	if (![spc_mb intValue]) return 131072;
	return [[self spc_mb] unsignedLongValue] * 1024;
}

- (NSNumber *)spc_mb;
{
	if (![spc_mb intValue]) return nil;
	return spc_mb;
}

- (void)startDatabase;
{
	[self startDatabaseWithArgs:nil];
	__block id me = self;
	[statmonitor setCompletionBlock:^(){ [me startIsDone]; }];
	[appController addOperation:statmonitor];
}

//	starts statmonitor, but does not add it as an operation
//	called directly by restore since it has other things to do after stone starts
- (void)startDatabaseWithArgs:(NSArray *)args;
{
	if ([WaitStone isStoneRunningForDatabase: self]) {
		isRunningCode = [NSNumber numberWithBool:true];
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Database is already running!"];
		[alert setInformativeText:@"No need to start it again!"];
		[alert addButtonWithTitle:@"Dismiss"];
		[alert runModal];
		return;
	}
	// should  check kernel settings and call helper tool if necessary
	[appController ensureSharedMemoryMB:spc_mb];
	[self createConfigFile];
	[self archiveCurrentLogFiles];
	statmonFiles = nil;

	[appController taskStart:@"Starting NetLDI, Stone, and Statmonitor . . .\n\n"];
	StartNetLDI *startNetLdi = [StartNetLDI forDatabase:self];
	StartStone *startStone = [StartStone forDatabase:self];
	[startStone setArgs:args];
	[startStone addDependency:startNetLdi];
	statmonitor = [Statmonitor forDatabase:self];
	[statmonitor addDependency:startStone];
	
	[appController addOperation:startNetLdi];
	[appController addOperation:startStone];
}

- (void)startIsDone;
{
	StartCacheWarmer *startCacheWarmer = [StartCacheWarmer forDatabase:self];
	[appController addOperation:startCacheWarmer];
	[self performSelector:@selector(refreshStatmonFiles)
			   withObject:nil
			   afterDelay:0.4];
	[appController performSelectorOnMainThread:@selector(databaseStartDone:) 
									withObject:self
								 waitUntilDone:NO];
}

- (void)startStop;
{
	if ([self isRunning]) {
		[self stopDatabase];
	} else {
		[self startDatabase];
	}
}

- (NSArray *)statmonFiles;
{
	if (statmonFiles) return statmonFiles;
	NSMutableArray *list = [NSMutableArray array];
	statmonFiles = list;
	NSString *path = [NSString stringWithFormat:@"%@/stat", [self directory]];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	NSString *gemstone = [self gemstone];
	while (file = [dirEnum nextObject]) {
		NSError *error = nil;
		NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, file];
		NSDictionary *attributes = [fileManager attributesOfItemAtPath:fullPath error:&error];
		if (error) {
			AppError(@"Unable to obtain attributes of %@ because %@", fullPath, [error description]);
		}
		NSMutableDictionary *statmon = [NSMutableDictionary dictionaryWithDictionary:attributes];
		[statmon setValue:file forKey:@"name"];
		[statmon setValue:fullPath forKey:@"path"];
		[statmon setValue:gemstone forKey:@"gemstone"];
		[list addObject:statmon];
	}
	statmonFiles = [statmonFiles sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
		return [[a valueForKey:NSFileCreationDate] compare:[b valueForKey:NSFileCreationDate]];
	}];
	return statmonFiles;
}

- (void)stopDatabase;
{
	[appController taskStart:@"Stopping NetLDI and Stone . . .\n\n"];
	StopNetLDI *stopNetLdi = [StopNetLDI forDatabase:self];
	StopStone *stopStone = [StopStone forDatabase:self];
	[stopStone addDependency:stopNetLdi];
	[statmonitor terminateTask];
	statmonitor = nil;
	__block id me = self;
	[stopStone setCompletionBlock:^(){ [me stopIsDone]; }];
	
	[appController addOperation:stopNetLdi];
	[appController addOperation:stopStone];
}

- (void)stopIsDone;
{
	[self	performSelector:@selector(refreshStatmonFiles)	
				 withObject:nil 
				 afterDelay:0.4];
	[appController performSelectorOnMainThread:@selector(databaseStopDone:) 
									withObject:self
								 waitUntilDone:NO];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
{
	if ([appController statmonTableView] == aTableView) {
		NSDictionary *row = [[self statmonFiles] objectAtIndex:rowIndex];
		NSString *key = [aTableColumn identifier];
		if ([key compare:@"start"] == NSOrderedSame) {
			return [row valueForKey:NSFileCreationDate];
		}
		if ([key compare:@"end"] == NSOrderedSame) {
			return [row valueForKey:NSFileModificationDate];
		}
		if ([key compare:@"duration"] == NSOrderedSame) {
			NSTimeInterval seconds = [[row valueForKey:NSFileModificationDate] timeIntervalSinceDate:[row valueForKey:NSFileCreationDate]];	// double
			NSUInteger number = seconds;
			if (number < 120) {
				return [NSString stringWithFormat:@"%lu secs", number];
			}
			number = number / 60;
			if (number < 120) {
				return [NSString stringWithFormat:@"%lu mins", number];
			}
			number = number / 60;	// hours
			if (number < 48) {
				return [NSString stringWithFormat:@"%lu hrs", number];
			}
			return [NSString stringWithFormat:@"%lu days", number / 24];
		}
		if ([key compare:@"size"] == NSOrderedSame) {
			NSNumber *number = [row valueForKey:NSFileSize];
			NSUInteger size = [number unsignedIntegerValue];
			if (size < 2048) {
				return [NSString stringWithFormat:@"%lu bytes", size];
			}
			size = size / 1024;
			if (size < 2048) {
				return [NSString stringWithFormat:@"%lu KB", size];
			}
			return [NSString stringWithFormat:@"%lu MB", size / 1024];
		}
		return @"foo";
	}
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
	NSTableView *tableView = [aNotification object];
	if ([appController statmonTableView] == tableView) {
		[appController setIsStatmonFileSelected:0 < [[tableView selectedRowIndexes] count]];
		return;
	}
}

- (NSString *)version;
{
	if (![version length]) return nil;
	return version;
}

@end
