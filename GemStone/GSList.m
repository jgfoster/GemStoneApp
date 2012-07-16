//
//  GSList.m
//  GemStone
//
//  Created by James Foster on 7/10/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "GSList.h"
#import "Utilities.h"

@implementation GSList

+ (NSArray *)processListUsingDatabase:(Database *)aDatabase;
{
	GSList *instance = [self forDatabase:aDatabase];
	return [instance processList];
}

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			@"-c",
			@"-v",
			@"-x",
			nil];
}

- (void)dataString:(NSString *)aString;
{
	[standardOutput appendString:aString];
}

- (void)doneWithError:(int)statusCode;
{
	foundNoProcesses = YES;
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/gslist", [database gemstone]];
}

- (NSArray *)processList;
{
	NSMutableArray *list = [NSMutableArray new];
	NSMutableDictionary *process = nil;
	foundNoProcesses = NO;
	[self run];
	if (foundNoProcesses) return list;
	for (NSString *line in [standardOutput componentsSeparatedByString:@"\n"]) {
		if ([line length]) {
			if ([line characterAtIndex:0] != ' ') {
				// next process
				if (process) {
					[list addObject:process];
				}
				process = [NSMutableDictionary new];
				[process setValue:line forKey:@"name"];
			} else {
				NSRange range = [line rangeOfString:@"="];
				NSString *key = [line substringToIndex:range.location];
				NSString *value = [line substringFromIndex:range.location + 1];
				key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				[process setValue:value forKey:key];
			}
		}
	}
	[list addObject:process];
	return list;
}

@end
