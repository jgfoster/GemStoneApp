//
//  Versions.m
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "NSFileManager+DirectoryLocations.h"
#import "Versions.h"

@interface Versions ()
- (void)downloadTaskFinished;
- (void)importTaskErrored:(NSString *)message;
- (void)importTaskFinished;
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

+ (NSString *)archiveFilePath;
{
	NSMutableString *path = [NSMutableString new];
	[path appendString:[[NSFileManager defaultManager] applicationSupportDirectory]];
	[path appendString:@"/Versions"];
	return [NSString stringWithString:path];
}

- (NSInteger)countOfVersions;
{
	return [versions count];
}

- (NSString *)createZipFileForVersionAtRow:(NSInteger)rowIndex;
{
	Version *version = [versions objectAtIndex:rowIndex];
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
			return [@"Please delete directory at:" stringByAppendingString:zipFilePath];
		}
		NSError *error;
		success = [[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:&error];
		if (!success) {
			return [@"Unable to delete existing file: " stringByAppendingString:[error localizedDescription]];
		}
	}
	success = [[NSFileManager defaultManager] 
			   createFileAtPath:zipFilePath 
			   contents:[NSData new] 
			   attributes:nil];
	if (!success) {
		return [@"Unable to create file: " stringByAppendingString:zipFilePath];
	}
	zipFile = [NSFileHandle fileHandleForWritingAtPath:zipFilePath];
	if (!zipFile) {
		return [@"Unable to open file: " stringByAppendingString:zipFilePath];
	}
	return nil;
}

- (void)downloadTaskErr:(NSNotification *)inNotification {
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
		NSDictionary *userInfo = [NSDictionary
								  dictionaryWithObject:string
								  forKey:@"string"];
		NSNotification *outNotification = [NSNotification
										notificationWithName:kVersionsTaskProgress 
										object:self
										userInfo:userInfo];
		[[NSNotificationCenter defaultCenter] postNotification:outNotification];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadCompletionNotification 
		 object:[inNotification object]];
		[self performSelector:@selector(downloadTaskFinished) withObject:nil afterDelay:0.5];
	}
}

- (void)downloadTaskFinished;
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
		NSString *message = @"'RETR 550' means that this version of GemStone/S 64 Bit is not available for the Macintosh.";
		NSDictionary *userInfo = [NSDictionary
								  dictionaryWithObject:message
								  forKey:@"string"];
		NSNotification *outNotification = [NSNotification
										notificationWithName:kVersionsTaskError 
										object:self
										userInfo:userInfo];
		[[NSNotificationCenter defaultCenter] postNotification:outNotification];
	}
}

- (void)downloadTaskOut:(NSNotification *)inNotification {
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length]) {
		[zipFile writeData:data];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadToEndOfFileCompletionNotification 
		 object:[inNotification object]];
	}
}

- (void)downloadVersionAtRow:(NSInteger)rowIndex;
{
	Version *version = [versions objectAtIndex:rowIndex];
	NSString *zippedFileName = [version zippedFileName];
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
	 stdOutSel:@selector(downloadTaskOut:) 
	 stdErrSel:@selector(downloadTaskErr:)];
	return;
}

- (void)encodeWithCoder:(NSCoder *)encoder;
{
	[encoder encodeObject:updateDate forKey:@"updateDate"];
	[encoder encodeObject:versions forKey:@"versions"];
	[encoder encodeObject:sortDescriptors forKey:@"sortDescriptors"];
}

- (id)getRow:(NSInteger)rowIndex column:(NSString *)columnIdentifier;
{
	Version *version = [versions objectAtIndex:rowIndex];
	return [version valueForKey:columnIdentifier];
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

- (void)importTaskErr:(NSNotification *)inNotification {
	[[NSNotificationCenter defaultCenter] 
	 removeObserver:self 
	 name:NSFileHandleReadCompletionNotification 
	 object:[inNotification object]];
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
		[self importTaskErrored:string];
	} else {
		[self importTaskFinished];
	}
}

- (void)importTaskErrored:(NSString *)message;
{
	NSDictionary *userInfo = [NSDictionary
							  dictionaryWithObject:message
							  forKey:@"string"];
	NSNotification *outNotification = [NSNotification
									   notificationWithName:kVersionsTaskError 
									   object:self
									   userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:outNotification];
	[self terminateTask];
}

- (void)importTaskFinished;
{
	NSRange range;
	range = [zipFilePath rangeOfString:[[NSFileManager defaultManager] applicationSupportDirectory]];
	if (0 == range.location) {
		[[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
	}
	task = nil;
	zipFilePath = nil;
	[self updateIsInstalled];
	[[NSNotificationCenter defaultCenter] postNotificationName:kVersionsTaskDone object:self];
}

- (void)importTaskOut:(NSNotification *)inNotification {
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
		NSDictionary *userInfo = [NSDictionary
								  dictionaryWithObject:string
								  forKey:@"string"];
		NSNotification *outNotification = [NSNotification
										   notificationWithName:kVersionsTaskProgress
										   object:self
										   userInfo:userInfo];
		[[NSNotificationCenter defaultCenter] postNotification:outNotification];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadCompletionNotification 
		 object:[inNotification object]];
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

- (id)objectInVersionsAtIndex:(NSUInteger)index;
{
	return [versions objectAtIndex:index];
}

- (NSString *)removeVersionAtRow:(NSInteger)rowIndex;
{
	Version *version = [versions objectAtIndex:rowIndex];
	NSError *error = nil;
	if ([version remove:&error]) {
		[self updateIsInstalled];
		return nil;
	}
	return [error localizedDescription];
}

- (void)save;
{
	[NSKeyedArchiver archiveRootObject:self toFile:[Versions archiveFilePath]];
}

// table sorting
- (void)sortUsingDescriptors:(NSArray *)anArray;
{
	sortDescriptors = anArray;
	[versions sortUsingDescriptors:sortDescriptors];
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

- (void)terminateTask;
{
	NSTask *myTask = task;
	task = nil;
	taskOutput = nil;
	[myTask terminate];
}

// read list of directories from FTP distribution site
- (void)update;
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
	path = @"/bin/sleep";	//	this allows testing cancel
	arguments = [NSArray arrayWithObjects:@"5", nil];
#endif
	[self 
	 startTaskPath:path 
	 arguments:arguments 
	 stdOutSel:@selector(updateTaskOut:) 
	 stdErrSel:@selector(updateTaskErr:)];
}

- (NSString *)updateDateString;
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

- (void)updateTaskErr:(NSNotification *)inNotification;
{
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if ([string length]) {
		NSDictionary *userInfo = [NSDictionary
								  dictionaryWithObject:string
								  forKey:@"string"];
		NSNotification *outNotification = [NSNotification
										   notificationWithName:kVersionsTaskProgress
										   object:self
										   userInfo:userInfo];
		[[NSNotificationCenter defaultCenter] postNotification:outNotification];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadCompletionNotification 
		 object:[inNotification object]];
		[self performSelector:@selector(updateTaskFinished) withObject:nil afterDelay:0.5];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:kVersionsTaskDone object:self];
}

- (void)updateTaskOut:(NSNotification *)inNotification;
{
	NSData *data = [[inNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	if (task && [string length]) {
		[taskOutput appendString:string];
		[[inNotification object] readInBackgroundAndNotify];
	} else {
		[[NSNotificationCenter defaultCenter] 
		 removeObserver:self 
		 name:NSFileHandleReadToEndOfFileCompletionNotification 
		 object:[inNotification object]];
	}
}

@end
