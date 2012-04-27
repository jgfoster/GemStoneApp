//
//  Versions.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "NSFileManager+DirectoryLocations.h"
#import "Versions.h"
#import "Version.h"

@interface Versions ()
- (NSString *)archiveFilePath;
- (void)importTaskFinished;
- (void)installTaskFinished;
- (void)startTaskPath:(NSString *)path 
			arguments:(NSArray *)arguments 
			stdOutSel:(SEL)stdOutSel 
			stdErrSel:(SEL) stdErrSel;
-(void)updateTaskFinished;
@end

@implementation Versions

@synthesize updateDate;
@synthesize versions;
@synthesize sortDescriptors;

- (NSString *)archiveFilePath;
{
	NSMutableString *path = [NSMutableString new];
	[path appendString:[[NSFileManager defaultManager] applicationSupportDirectory]];
	[path appendString:@"/Versions"];
	return [NSString stringWithString:path];
}

- (void)awakeFromNib;
{
	NSLog(@"Versions-awakeFromNib");
	Versions *archive = [NSKeyedUnarchiver unarchiveObjectWithFile:[self archiveFilePath]];
	if (archive) {
		updateDate = [archive updateDate];
		versions = [archive versions];
		sortDescriptors = [archive sortDescriptors];
		[self updateUI];
	}
}

- (void)cancelTask
{
	[task terminate];
	task = nil;
	[[NSApp delegate] taskFinished];
}

- (void)encodeWithCoder:(NSCoder *)encoder;
{
	[encoder encodeObject:updateDate forKey:@"updateDate"];
	[encoder encodeObject:versions forKey:@"versions"];
	[encoder encodeObject:sortDescriptors forKey:@"sortDescriptors"];
}

- (void)import:(NSURL *)url
{
	zipFilePath = [url path];
	NSArray	*arguments = [NSArray arrayWithObjects:
				 zipFilePath, 
				 @"-d",
				 [[NSFileManager defaultManager] applicationSupportDirectory],
				 nil];
	[self 
	 startTaskPath:@"/usr/bin/unzip" 
	 arguments:arguments 
	 stdOutSel:@selector(importTaskOut:) 
	 stdErrSel:@selector(importTaskErr:)];
}

- (void)importTaskErr:(NSNotification *)notification {
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setAlertStyle:NSCriticalAlertStyle];
        [alert setMessageText:@"Import Failed"];
        [alert setInformativeText:string];
        [alert addButtonWithTitle:@"Dismiss"];
        [alert runModal];
		[self cancelTask];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadCompletionNotification 
		 object:[notification object]];
		[self performSelector:@selector(importTaskFinished) withObject:nil afterDelay:0.1];
	}
}

- (void)importTaskFinished;
{
	NSRange range;
	range = [zipFilePath rangeOfString:[[NSFileManager defaultManager] applicationSupportDirectory]];
	if (0 == range.location) {
		[[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
	}
	zipFilePath = nil;
	task = nil;
	[self updateIsInstalled];
	[self updateUI];
	[[NSApp delegate] taskFinished];
}

- (void)importTaskOut:(NSNotification *)notification {
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
		[[NSApp delegate] taskProgress:string];
		[[notification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadCompletionNotification 
		 object:[notification object]];
	}
}

- (id)init 
{
	if (self = [super init]) {
		versions = [NSMutableArray new];
		task = nil;
		taskOutput = nil;
	}
	return self;
}

- (id) initWithCoder: (NSCoder *)coder
{
	if (self = [super init])
	{
		updateDate = [coder decodeObjectForKey:@"updateDate"];
		versions = [coder decodeObjectForKey:@"versions"];
		sortDescriptors = [coder decodeObjectForKey:@"sortDescriptors"];
	}
	return self;
}

- (NSArray *)installedVersions;
{
	NSMutableArray *installedVersions = [NSMutableArray arrayWithCapacity:[versions count]];
	for (Version *version in versions) {
		if (version.isInstalled) {
			[installedVersions addObject:version];
		}
	}
	return installedVersions;
}

- (void)installVersion:(Version *)version;
{
	NSString *zippedFileName = [version zippedFileName];
	zipFilePath = [NSMutableString new];
	NSMutableString *path = [NSMutableString new];
	[path appendString:[[NSFileManager defaultManager] applicationSupportDirectory]];
	[path appendString:@"/"];
	[path appendString:zippedFileName];
	zipFilePath = [NSString stringWithString:path];
	BOOL exists, isDirectory = NO, success;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:zipFilePath isDirectory:&isDirectory];
	if (exists) {
		if (isDirectory) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setAlertStyle:NSCriticalAlertStyle];
			[alert setMessageText:@"Please delete directory at:"];
			[alert setInformativeText:zipFilePath];
			[alert addButtonWithTitle:@"Dismiss"];
			[alert runModal];
			return;
		}
		NSError *error;
		success = [[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:&error];
		if (!success) {
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setAlertStyle:NSCriticalAlertStyle];
			[alert setMessageText:@"Unable to delete existing file"];
			[alert setInformativeText:[error localizedDescription]];
			[alert addButtonWithTitle:@"Dismiss"];
			[alert runModal];
			return;
		}
	}
	success = [[NSFileManager defaultManager] 
			   createFileAtPath:zipFilePath 
			   contents:[NSData new] 
			   attributes:nil];
	if (!success) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert setMessageText:@"Unable to create file"];
		[alert setInformativeText:zipFilePath];
		[alert addButtonWithTitle:@"Dismiss"];
		[alert runModal];
		return;
	}
	zipFile = [NSFileHandle fileHandleForWritingAtPath:zipFilePath];
	if (!zipFile) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert setMessageText:@"Unable to open file"];
		[alert setInformativeText:zipFilePath];
		[alert addButtonWithTitle:@"Dismiss"];
		[alert runModal];
		return;
	}
	[[NSApp delegate] cancelMethod:@selector(cancelInstallVersion)];
	[[NSApp delegate] startTaskProgressSheet];
	NSArray	*arguments;
	NSMutableString *ftp = [NSMutableString new];
	[ftp appendString:@"ftp://ftp.gemstone.com/pub/GemStone64/"];
	[ftp appendString:version.version];
	[ftp appendString:@"/"];
	[ftp appendString:zippedFileName];
	arguments = [NSArray arrayWithObjects:
				 ftp, 
				 @"--user",
				 @"anonymous:password",
				 nil];
	[self 
	 startTaskPath: @"/usr/bin/curl" 
	 arguments:arguments 
	 stdOutSel:@selector(installTaskOut:) 
	 stdErrSel:@selector(installTaskErr:)];
}

- (void)installTaskErr:(NSNotification *)notification {
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
		[[NSApp delegate] taskProgress:string];
		[[notification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadCompletionNotification 
		 object:[notification object]];
		[self performSelector:@selector(installTaskFinished) withObject:nil afterDelay:0.1];
	}
}

- (void)installTaskFinished;
{
	[zipFile closeFile];
	zipFile = nil;
	if (!task) return;		// task cancelled!
	task = nil;
	int fileSize = [[[NSFileManager defaultManager] 
					 attributesOfItemAtPath:zipFilePath 
					 error:nil] fileSize];
	if (fileSize) {
		NSURL *url = [NSURL fileURLWithPath:zipFilePath isDirectory:NO];
		zipFilePath = nil;
		[self import:url];
	} else {
		[[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
		zipFilePath = nil;
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert setMessageText:@"Download Failed!"];
		[alert setInformativeText:@"'RETR 550' means that this version of GemStone/S 64 Bit is not available for the Macintosh."];
		[alert addButtonWithTitle:@"Dismiss"];
		[alert runModal];
		[[NSApp delegate] taskFinished];
	}
}

- (void)installTaskOut:(NSNotification *)notification {
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]) {
		[zipFile writeData:data];
		[[notification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadToEndOfFileCompletionNotification 
		 object:[notification object]];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [versions count];
}

- (void)removeVersion:(Version *)version;
{
	NSError *error = nil;
	if ([version remove:&error]) {
		[self updateIsInstalled];
		return;
	}
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert setMessageText:@"Removal Failed!"];
	[alert setInformativeText:[error localizedDescription]];
	[alert addButtonWithTitle:@"Dismiss"];
	[alert runModal];
}

// get table cell
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	Version *version = [versions objectAtIndex:rowIndex];
	NSString *columnIdentifier = [aTableColumn identifier];
	SEL selector = NSSelectorFromString(columnIdentifier);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	id object = [version performSelector:selector];
#pragma clang diagnostic pop
	return object;
}

// set table cell
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	Version *version = [versions objectAtIndex:rowIndex];
	NSString *columnIdentifier = [aTableColumn identifier];
	SEL selector = NSSelectorFromString(columnIdentifier);
	if (selector != @selector(isInstalledNumber)) {
		NSLog(@"Invalid attempt to edit Versions-tableView:setObjectValue:%@ forTableColumn:%@ row:%ld", anObject, columnIdentifier, rowIndex);
		return;
	}
	if ([anObject boolValue]) {
		[self installVersion:version];
	} else {
		[self removeVersion:version];
	}
}

// table sorting
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
	sortDescriptors = [tableView sortDescriptors];
	[versions sortUsingDescriptors:sortDescriptors];
	[tableView reloadData];
}

- (void)startTaskPath:(NSString *)path arguments:(NSArray *)arguments stdOutSel:(SEL)stdOutSel stdErrSel:(SEL) stdErrSel
{
	if (task) {
		NSLog(@"task should not exist!");
		return;
	}
    task = [NSTask new];
	[task setCurrentDirectoryPath:[[NSFileManager defaultManager] applicationSupportDirectory]];
	[task setLaunchPath:path];
	[task setArguments:arguments];
    [task setStandardOutput:[NSPipe pipe]];
    [task setStandardError: [NSPipe pipe]];
    NSFileHandle *taskOut = [[task standardOutput] fileHandleForReading];
    NSFileHandle *taskErr = [[task standardError]  fileHandleForReading];
	
	[[NSNotificationCenter defaultCenter] 
	 addObserver:self 
	 selector:stdErrSel
	 name:NSFileHandleReadCompletionNotification
	 object:taskErr];
    [taskErr readInBackgroundAndNotify];
	
	[[NSNotificationCenter defaultCenter] 
	 addObserver:self 
	 selector:stdOutSel 
	 name:NSFileHandleReadCompletionNotification
	 object:taskOut];
    [taskOut readInBackgroundAndNotify];
    taskOutput = [NSMutableString new];
	[task launch];
}

// read list of directories from FTP distribution site
- (void)update
{
	NSArray	*arguments;
	NSString *path;
#if 1
    path = @"/usr/bin/curl";
	arguments = [NSArray arrayWithObjects:
						  @"ftp://ftp.gemstone.com/pub/GemStone64/", 
						  @"--user",
						  @"anonymous:password",
						  nil];
#else
	path = @"/bin/sleep";
	arguments = [NSArray arrayWithObjects:@"5", nil];
#endif
	[self 
	 startTaskPath:path 
	 arguments:arguments 
	 stdOutSel:@selector(updateTaskOut:) 
	 stdErrSel:@selector(updateTaskErr:)];
}

- (NSString *)updateDateString
{
	if (!updateDate) {
		return @"";
	}
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"dd MMM yyyy"];
	return [dateFormatter stringFromDate:updateDate];
}

- (void)updateIsInstalled;
{
	for (id version in versions) {
		[version updateIsInstalled];
	}
}

- (void)updateTaskErr:(NSNotification *)notification {
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
		[[NSApp delegate] taskProgress:string];
		[[notification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadCompletionNotification 
		 object:[notification object]];
		[self performSelector:@selector(updateTaskFinished) withObject:nil afterDelay:0.1];
	}
}

-(void)updateTaskFinished;
{
	NSString *string = taskOutput;
	taskOutput = nil;
	if (!task) return;		// task cancelled!

	NSMutableArray *lines = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@"\n"]];
	[lines removeObject:@""];
	versions = [NSMutableArray arrayWithCapacity:[lines count]];
	NSRange range = {0, 5};
	NSDate *today = [NSDate date];
	
	NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit fromDate:today];
    NSInteger thisYear = [components year];
	NSString *yearString = [NSString stringWithFormat:@"%d", thisYear];

	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"MMM dd, yyyy"];

	for (string in lines) {
		NSMutableArray *fields = [NSMutableArray arrayWithArray:[string componentsSeparatedByString:@" "]];
		[fields removeObject:@""];
		[fields removeObjectsInRange:range];
		if ([[fields objectAtIndex:2] rangeOfString:@":"].location != NSNotFound) {
			[fields replaceObjectAtIndex:2 withObject:yearString];
		}
		NSString *dateString = [NSString stringWithFormat:@"%@ %@, %@", 
								[fields objectAtIndex:0], 
								[fields objectAtIndex:1], 
								[fields objectAtIndex:2]];
		NSDate *date = [formatter dateFromString:dateString];
		if ([today compare:date] == NSOrderedAscending) {
			dateString = [NSString stringWithFormat:@"%@ %@, %d", 
						  [fields objectAtIndex:0], 
						  [fields objectAtIndex:1], 
						  thisYear - 1];
			date = [formatter dateFromString:dateString];
		}
		Version *version = [Version new];
		[version setIsInstalled:NO];
		[version setVersion:[fields objectAtIndex:3]];
		[version setDate:date];
		[versions addObject:version];
	}
	updateDate = today;
	task = nil;
	[self updateIsInstalled];
	if (sortDescriptors) {
		[versions sortUsingDescriptors:sortDescriptors];
	}
	[self updateUI];
	[[NSApp delegate] taskFinished];
}

- (void)updateTaskOut:(NSNotification *)notification {
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if (task && [string length]) {
		[taskOutput appendString:string];
		[[notification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadToEndOfFileCompletionNotification 
		 object:[notification object]];
	}
}

- (void)updateUI
{
	[NSKeyedArchiver archiveRootObject:self toFile:[self archiveFilePath]];
	[updateDateField setStringValue:[self updateDateString]];
	[versionsTable reloadData];
}



@end
