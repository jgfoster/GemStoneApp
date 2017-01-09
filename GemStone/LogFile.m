//
//  LogFile.m
//  GemStone
//
//  Created by James Foster on 7/11/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "LogFile.h"

@implementation LogFile

@synthesize path;
@synthesize type;
@synthesize pid;
@synthesize date;
@synthesize size;

+ (LogFile *)logFileFromDictionary:(NSDictionary *)aDictionary;
{
	LogFile *logFile = [self new];
	[logFile initializeFromDictionary:aDictionary];
	return logFile;
}

- (void)initializeFromDictionary:(NSDictionary *)aDictionary;
{
	date = [aDictionary valueForKey:NSFileModificationDate];
	path = [aDictionary valueForKey:@"path"];
	NSString *name = [aDictionary valueForKey:@"name"];
	name = [name substringToIndex:[name length] - 4];
	type = name;
	size = [aDictionary valueForKey:NSFileSize];
	NSString *stone = [aDictionary valueForKey:@"stone"];
	if ([name length] <= [stone length]) return;
	if (![[name substringToIndex:[stone length]] isEqualToString:stone]) return;
	NSRange range = {[stone length], 1};
	if (![@"_" isEqualToString:[name substringWithRange:range]]) return;
	type = [name substringFromIndex:range.location + 1];
	NSInteger index = -1;
	for (NSUInteger i = 0; i < [type length] && index + 1 == i; ++i) {
		unichar myChar = [type characterAtIndex:i];
		if ('0' <= myChar && myChar <= '9') {
			index = i;
		}
	}
	pid = [type substringToIndex:index + 1];
	type = [type substringFromIndex:index + 1];
}

- (void)open;
{
	[[NSWorkspace sharedWorkspace] openFile:path];
}

@end
