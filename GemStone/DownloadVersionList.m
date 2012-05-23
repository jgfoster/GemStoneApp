//
//  DownloadVersionList.m
//  GemStone
//
//  Created by James Foster on 5/7/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "DownloadVersionList.h"
#import "Version.h"

@implementation DownloadVersionList

@synthesize versions;

- (NSArray *)arguments;
{
	return [NSArray arrayWithObjects:
			@"ftp://ftp.gemstone.com/pub/GemStone64/", 
			@"--user",
			@"anonymous:password",
			nil];
}

- (void)data:(NSData *)data;
{
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	[taskOutput appendString:string];
}

- (void)done;
{
	NSString *string = taskOutput;
	taskOutput = nil;
	if (!task) return;		// task cancelled!
	task = nil;
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
	
	for (id string in lines) {
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
		NSString *name = [fields objectAtIndex:3];
		NSDictionary *version = [NSMutableDictionary dictionaryWithCapacity:2];
		[version setValue:name forKey:@"name"];
		[version setValue:date forKey:@"date"];
		[versions addObject:version];
	}

	[self notifyDone];
}
	
- (id)init;
{
	if (self = [super init]) {
		taskOutput = [NSMutableString new];
	}
	return self;
}

- (NSString *)path;
{
	return @"/usr/bin/curl";
}

@end
