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
#import "Utilities.h"
#import "StartCacheWarmer.h"
#import "StartNetLDI.h"
#import "StartStone.h"
#import "Statmonitor.h"
#import "StopNetLDI.h"
#import "StopStone.h"
#import "Terminal.h"
#import "Topaz.h"
#import "Utilities.h"
#import "Version.h"
#import "VSD.h"
#import "WaitStone.h"

@implementation Database

@synthesize identifier		= _identifier;
@synthesize isRunning		= _isRunning;
@synthesize statmonFiles	= _statmonFiles;
@synthesize statmonitor		= _statmonitor;

// following are part of the DataModel handled by Core Data
@dynamic indexInArray;
@dynamic lastStartDate;
@dynamic name;
@dynamic netLDI;
@dynamic spc_mb;
@dynamic version;

- (void)archiveCurrentLogFiles {
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
			if ([[baseList objectAtIndex:i] isEqualToString:[thisList objectAtIndex:i]]) {
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

- (void)archiveCurrentTransactionLogs {
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

- (void)backup {
	//	get path to backup
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setAllowedFileTypes:[NSArray arrayWithObjects:@"bak",@"BAK",@"gz",@"GZ", nil]];
	[panel setTitle:@"Create From a Full Backup"];
    [panel setPrompt:@"Backup"];
	[panel setMessage:@"Name of on-line backup:"];
    [panel setCanSelectHiddenExtension:YES];
	[panel setNameFieldStringValue:[NSString stringWithFormat:@"%@.bak.gz",[self name]]];
	[panel setExtensionHidden:NO];
    [panel setTreatsFilePackagesAsDirectories:NO];
    [panel beginSheetModalForWindow:[NSApp mainWindow]
                  completionHandler:^(NSInteger result) {
					  [panel orderOut:nil];
                      if (result != NSFileHandlingPanelOKButton) return;
                      NSString *path = [[panel URL] path];
                      Topaz *topaz = [Topaz database:self
                                      do:^(Topaz *aTopaz){ [aTopaz fullBackupTo:path]; }];
                      [appController addOperation:topaz];
                  }];
}

- (void)createConfigFiles {
	NSError *error = nil;
	NSString *inPath;
	NSString *inString;
	NSString *outPath;
	NSString *outString;
	
	// create template for stone executable config file
	outPath = [self pathToStoneConfigFile];
	if (![fileManager fileExistsAtPath:outPath]) {
		inPath = [[NSBundle mainBundle] pathForResource:@"stone" ofType:@"conf"];
		if(!inPath) { AppError(@"Unable to find template for stone.conf"); }
		inString = [NSString stringWithContentsOfFile:inPath
											 encoding:NSUTF8StringEncoding
												error:&error];
		if(!inString) { AppError(@"Unable to read template at %@", inPath); }
		outString = inString;	// no substitutions needed now
		if (![fileManager
			  createFileAtPath:outPath
			  contents:[outString dataUsingEncoding:NSUTF8StringEncoding]
			  attributes:nil]) {
			AppError(@"Unable to create config file at %@", outPath);
		};
	}

	// if other config files exist, then done
	outPath = [self pathToGemConfigFile];
	if ([fileManager fileExistsAtPath:outPath]) { return; }
	
	// create template for gem executable config file
	inPath = [[NSBundle mainBundle] pathForResource:@"gem" ofType:@"conf"];
	if(!inPath) { AppError(@"Unable to find template for gem.conf"); }
	inString = [NSString stringWithContentsOfFile:inPath
										 encoding:NSUTF8StringEncoding
											error:&error];
	if(!inString) { AppError(@"Unable to read template at %@", inPath); }
	outString = inString;	// no substitutions needed now
	if (![fileManager
		  createFileAtPath:outPath
		  contents:[outString dataUsingEncoding:NSUTF8StringEncoding]
		  attributes:nil]) {
		AppError(@"Unable to create config file at %@", outPath);
	};

	// create system config file
	inPath = [[NSBundle mainBundle] pathForResource:@"system" ofType:@"conf"];
	if(!inPath) { AppError(@"Unable to find template for system.conf"); }
	inString = [NSString stringWithContentsOfFile:inPath
										 encoding:NSUTF8StringEncoding
											error:&error];
	if(!inString) { AppError(@"Unable to read template at %@", inPath); }
	outPath = [self pathToSystemConfigFile];
	NSString *directory = [self directory];
	outString = [NSString stringWithFormat:inString, directory, directory, directory, directory];
	if (![fileManager
			createFileAtPath:outPath
			contents:[outString dataUsingEncoding:NSUTF8StringEncoding]
			attributes:nil]) {
		AppError(@"Unable to create config file at %@", outPath);
	};
}

- (void)createDirectories {
	[self createDirectory:@"conf"];
	[self createDirectory:@"data"];
	[self createDirectory:@"data/archive"];
	[self createDirectory:@"log"];
	[self createDirectory:@"log/archive"];
	[self createDirectory:@"stat"];
	[self createLocksDirectory];
}

- (void)createDirectory:(NSString *)aString {
	NSString *path = [NSString stringWithFormat:@"%@/%@", [self directory], aString];
	NSError *error = nil;
	if ([fileManager
		 createDirectoryAtPath:path
		 withIntermediateDirectories:YES
		 attributes:nil
		 error:&error]) return;
	AppError(@"Unable to create %@ because %@!", path, [error description]);
}

- (void)createLocksDirectory {
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

- (void)createTopazIniFile {
	NSString *directory = [self directory];
	NSString *path = [NSString stringWithFormat:@"%@/.topazini", directory];
	NSMutableString *string = [NSMutableString new];
	[string appendString: @"! default initialization for Topaz session\n"];
	[string appendString: @"set user DataCurator pass swordfish\n"];
	[string appendFormat: @"set gems %@\n", [self name]];
	[string appendString: @"login\n"];
	if (![fileManager
		  createFileAtPath:path
		  contents:[string dataUsingEncoding:NSUTF8StringEncoding]
		  attributes:nil]) {
		AppError(@"Unable to create .topazini file at %@", path);
	};
}

- (NSArray *)dataFiles {
	NSString *path = [NSString stringWithFormat:@"%@/data", [self directory]];
	NSError *error = nil;
	NSArray *fullList = [fileManager contentsOfDirectoryAtPath:path error:&error];
	if (!fullList) {
		AppError(@"Unable to get contents of %@ because %@", path, [error description]);
	}
	NSMutableArray *list = [NSMutableArray arrayWithCapacity:[fullList count]];
	for (NSString *each in fullList) {
		if (![each isEqualToString:@"archive"]) {
			[list addObject:each];
		}
	}
	return list;
}

- (void)deleteAll {
	NSString *path = [self directory];
	NSError *error = nil;
	if ([fileManager removeItemAtPath:path error:&error]) return;
	AppError(@"Unable to delete %@ because %@", path, [error description]);
}

- (void)deleteFilesIn:(NSString *)aString {
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

- (void)deleteOldLogFiles {
	[self deleteFilesIn:@"log/archive"];
}

- (void)deleteOldTranLogs {
	[self deleteFilesIn:@"data/archive"];
}

- (void)deleteStatmonFilesAtIndexes:(NSIndexSet *)indexes {
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		NSDictionary *statmon = [self.statmonFiles objectAtIndex:idx];
		NSError *error = nil;
		NSString *path = [statmon objectForKey:@"path"];
		if (![fileManager removeItemAtPath:path error:&error]) {
			AppError(@"Unable to delete %@ because %@", path, [error description]);
		}
	}];
	_statmonFiles = nil;
	[[appController statmonTableView] reloadData];
}

- (NSString *)descriptionOfFilesIn:(NSString *)aString {
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

- (NSString *)descriptionOfOldLogFiles {
	return [self descriptionOfFilesIn:@"log"];
}
- (NSString *)descriptionOfOldTranLogs {
	return [self descriptionOfFilesIn:@"data"];
}

- (NSString *)directory {
	return [NSString stringWithFormat: @"%@/db%@", basePath, [self identifier]];
}

- (void)doubleClickStatmon:(id)sender {
	[self openStatmonFilesAtIndexes:[NSIndexSet indexSetWithIndex:[sender clickedRow]]];
}

- (NSString *)gemstone {
	NSString *path = [NSString stringWithFormat: @"%@/GemStone64Bit%@-i386.Darwin", basePath, [self version]];
	return path;
}

- (NSString *)gemToolsLogin {
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

- (void)gsList:(NSArray *)list {
	self.isRunning = NO;
	for (NSDictionary *process in list) {
		NSString *string = [process valueForKey:@"version"];
		if ([string isEqualToString:self.version]) {
			string = [process valueForKey:@"GEMSTONE"];
			if ([string isEqualToString:[self gemstone]]) {
				string = [process valueForKey:@"logfile"];
				NSString *directory = [self directory];
				NSRange range = [string rangeOfString:directory];
				if (range.location == 0) {
					string = [process valueForKey:@"type"];
					if ([string isEqualToString:@"Stone"]) {
						self.isRunning = YES;
						return;
					}
				}
			}
		}
	}
}

- (NSNumber *)identifier {
	if (![self.identifier intValue]) {
		_identifier = [appController nextDatabaseIdentifier];
		[self createDirectories];
		self.version = [appController mostAdvancedVersion];
		[self installGlassExtent];
		[self createConfigFiles];
	}
	return self.identifier;
}

- (NSString *)infoForDataFile:(NSString *)file {
	return [CopyDBF infoForFile:file in:self];
}

- (void)installBaseExtent {
	[self installExtent:@"extent0.dbf"];
}

- (void)installExtent:(NSString *)aString {
	NSError *error = nil;
	NSString *target = [NSString stringWithFormat:@"%@/data/extent0.dbf", [self directory]];
	if ([fileManager fileExistsAtPath:target]) {
		if (self.lastStartDate) {
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
	[self performSelectorInBackground:@selector(installExtentA:)
						   withObject:aString];
}

- (void)installExtentA:(NSString *)aString {
	NSError *error = nil;
	NSString *target = [NSString stringWithFormat:@"%@/data/extent0.dbf", [self directory]];
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
	self.lastStartDate = nil;
	[appController taskFinishedAfterDelay];
	[appController updateDatabaseList:nil];
}

- (void)installGlassExtent {
	[self installExtent:@"extent0.seaside.dbf"];
}

- (NSString *)isRunningString {
	return [self isRunning] ? @"yes" : @"no";
}

- (NSArray *)logFiles {
	NSMutableArray *list = [NSMutableArray array];
	NSString *path = [NSString stringWithFormat:@"%@/log", [self directory]];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
	NSString *file;
	while (file = [dirEnum nextObject]) {
		if (1 < [[file pathComponents] count]) {
			[dirEnum skipDescendents];
			continue;
		}
		if ((4 < [file length]) && ([@".log" isEqualToString:[file substringFromIndex:[file length]-4]])) {
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

- (NSString *)name {
	if ([self.name length]) return self.name;
	return [NSString stringWithFormat:@"gs64stone%@", self.identifier];
}

- (NSString *)netLDI {
	if ([self.netLDI length]) return self.netLDI;
	return [NSString stringWithFormat:@"netldi%@", self.identifier];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	if ([appController statmonTableView] == aTableView) {
		return [self.statmonFiles count];
	}
	return 0;
}

- (void)open {
	[[NSWorkspace sharedWorkspace] openFile:[self directory]];
}

- (void)openDefaultConfigFileb {
	NSString *path = [NSString stringWithFormat:@"%@/data/system.conf",[self gemstone]];
	[[NSWorkspace sharedWorkspace] openFile:path];
}

- (void)openGemConfigFile {
	[[NSWorkspace sharedWorkspace] openFile:[self pathToGemConfigFile]];
}

- (void)openStoneConfigFile {
	[[NSWorkspace sharedWorkspace] openFile:[self pathToStoneConfigFile]];
}

- (void)openSystemConfigFile {
	[[NSWorkspace sharedWorkspace] openFile:[self pathToSystemConfigFile]];
}

- (void)openStatmonFilesAtIndexes:(NSIndexSet *)indexes {
	[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
		NSDictionary *statmon = [self.statmonFiles objectAtIndex:idx];
		NSString *path = [statmon objectForKey:@"path"];
		[VSD openPath:path usingDatabase:self];
	}];
}

- (IBAction)openTerminal:(id)sender {
	[Terminal doScript:@"" forDatabase:self];
}

- (IBAction)openTopaz:(id)sender {
	[Terminal doScript:@"topaz -l" forDatabase:self];
}

- (IBAction)openWebTools:(id)sender {
	[Terminal doScript:@"(cd ../webtools; ./start)" forDatabase:self];
}

- (NSString *)pathToGemConfigFile {
	return [NSString stringWithFormat:@"%@/conf/gem.conf", [self directory]];
}

- (NSString *)pathToStoneConfigFile {
	return [NSString stringWithFormat:@"%@/conf/%@.conf", [self directory], [self name]];
}

- (NSString *)pathToSystemConfigFile {
	return [NSString stringWithFormat:@"%@/conf/system.conf", [self directory]];
}

- (void)refreshStatmonFiles {
	_statmonFiles = nil;
}

- (void)restore {
	//	get path to backup
	NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setResolvesAliases:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setTitle:@"Restore From a Full Backup"];
    [panel setPrompt:@"Restore"];
    [panel setMessage:@"Select an on-line backup:"];
    [panel setCanSelectHiddenExtension:YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"bak",@"BAK",@"gz",@"GZ", nil]];
    [panel setAllowsMultipleSelection:NO];
    [panel setTreatsFilePackagesAsDirectories:NO];
    [panel beginSheetModalForWindow:[NSApp mainWindow]
               completionHandler:^(NSInteger result) {
				   [panel orderOut:nil];
                   if (result != NSFileHandlingPanelOKButton) return;
                   __block id me = self;		//	blocks get a COPY of referenced objects unless explicitly shared
                   NSString *path = [[[panel URLs] objectAtIndex:0] path];
                   //	defines statmonitor, but does not add it as an operation
                   [self startDatabaseWithArgs:[NSArray arrayWithObject:@"-R"]];
                   Topaz *topaz = [Topaz database:self
                                   do:^(Topaz *aTopaz) { [aTopaz restoreFromBackup:path]; } ];
                   [topaz addDependency:self.statmonitor];
				   [topaz setCompletionBlock:^(){ [me startIsDone]; me = nil; }];
                   [appController addOperation:self.statmonitor];
                   [appController addOperation:topaz];
               }];
 }

- (void)setIsRunning:(BOOL)aBool {
	_isRunning = aBool;
	if (aBool) {
		self.lastStartDate = [NSDate date];
	}
}

- (void)setVersion:(NSString *)aString {
	if (self.version == aString) return;
	self.version = aString;
	[self installGlassExtent];
}

- (NSString *)sizeForDataFile:(NSString *)file {
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

- (void)startDatabase {
	[self startDatabaseWithArgs:nil];
	__block id me = self;		//	blocks get a COPY of referenced objects unless explicitly shared
	StartCacheWarmer *cacheWarmer = [StartCacheWarmer forDatabase:self];
	[cacheWarmer setCompletionBlock:^(){ [me startIsDone]; me = nil; }];
	[cacheWarmer addDependency:self.statmonitor];
	[appController addOperation:cacheWarmer];
	[appController addOperation:self.statmonitor];
}

//	starts statmonitor, but does not add it as an operation
//	called directly by restore since it has other things to do after stone starts
- (void)startDatabaseWithArgs:(NSArray *)args {
	if ([WaitStone isStoneRunningForDatabase: self]) {
		_isRunning = YES;
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Database is already running!"];
		[alert setInformativeText:@"No need to start it again!"];
		[alert addButtonWithTitle:@"Dismiss"];
		[alert runModal];
		return;
	}
	[appController ensureSharedMemory];
	[self createConfigFiles];
	[self createTopazIniFile];
	_statmonFiles = nil;

	[appController taskStart:@"Starting NetLDI, Stone, and Statmonitor . . .\n\n"];
	StartNetLDI *startNetLdi = [StartNetLDI forDatabase:self];
	StartStone *startStone = [StartStone forDatabase:self];
	[startStone setArgs:args];
	[startStone addDependency:startNetLdi];
	self.statmonitor = [Statmonitor forDatabase:self];
	[self.statmonitor addDependency:startStone];
	
	[appController addOperation:startNetLdi];
	[appController addOperation:startStone];
}

- (void)startIsDone {
	[self performSelector:@selector(refreshStatmonFiles)
			   withObject:nil
			   afterDelay:0.4];
	[appController performSelectorOnMainThread:@selector(databaseStartDone:) 
									withObject:self
								 waitUntilDone:NO];
}

- (void)startStop {
	if ([self isRunning]) {
		[self stopDatabase];
	} else {
		[self startDatabase];
	}
}

- (NSArray *)statmonFiles {
	if (self.statmonFiles) return self.statmonFiles;
	NSMutableArray *list = [NSMutableArray array];
	_statmonFiles = list;
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
	_statmonFiles = [self.statmonFiles sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
		return [[a valueForKey:NSFileCreationDate] compare:[b valueForKey:NSFileCreationDate]];
	}];
	return self.statmonFiles;
}

- (void)stopDatabase {
	[appController taskStart:@"Stopping NetLDI and Stone . . .\n\n"];
	StopNetLDI *stopNetLdi = [StopNetLDI forDatabase:self];
	StopStone *stopStone = [StopStone forDatabase:self];
	[stopStone addDependency:stopNetLdi];
	[self.statmonitor cancel];
	self.statmonitor = nil;
	__block id me = self;		//	blocks get a COPY of referenced objects unless explicitly shared
	[stopStone setCompletionBlock:^(){ [me stopIsDone]; me = nil; }];
	
	[appController addOperation:stopNetLdi];
	[appController addOperation:stopStone];
}

- (void)stopIsDone {
	[self archiveCurrentLogFiles];
	[self	performSelector:@selector(refreshStatmonFiles)
				 withObject:nil 
				 afterDelay:0.4];
	[appController performSelectorOnMainThread:@selector(databaseStopDone:) 
									withObject:self
								 waitUntilDone:NO];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([appController statmonTableView] == aTableView) {
		NSDictionary *row = [[self statmonFiles] objectAtIndex:rowIndex];
		NSString *key = [aTableColumn identifier];
		if ([key isEqualToString:@"start"]) {
			return [row valueForKey:NSFileCreationDate];
		}
		if ([key isEqualToString:@"end"]) {
			return [row valueForKey:NSFileModificationDate];
		}
		if ([key isEqualToString:@"duration"]) {
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
		if ([key isEqualToString:@"size"]) {
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

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView *tableView = [aNotification object];
	if ([appController statmonTableView] == tableView) {
		[appController setIsStatmonFileSelected:0 < [[tableView selectedRowIndexes] count]];
		return;
	}
}

- (NSString *)version {
	[self willAccessValueForKey:@"version"];
	NSString *myVersion = [self primitiveValueForKey:@"version"];
	[self didAccessValueForKey:@"version"];
	if (![myVersion length]) return nil;
	return myVersion;
}

@end
