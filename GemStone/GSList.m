//
//  GSList.m
//  GemStone
//
//  Created by James Foster on 7/10/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "GSList.h"
#import "Utilities.h"

@interface GSList ()

@property 	BOOL	foundNoProcesses;

@end

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

- (NSString *)binName;
{
	return @"gslist";
}

- (void)done;
{
	[super done];
	if ([self.standardOutput length]) return;
	NSLog(@"done with no output!?");
}

- (void)doneWithError:(int)statusCode;
{
	self.foundNoProcesses = YES;
	[super doneWithError:0];	//	Not really an error to have no processes
}

- (NSArray *)processList;
{
	NSMutableArray *list = [NSMutableArray new];
	NSMutableDictionary *process = nil;
	self.foundNoProcesses = NO;
	[self main];
	if (self.foundNoProcesses) return list;
	for (NSString *line in [self.standardOutput componentsSeparatedByString:@"\n"]) {
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
	if (process) {
		[list addObject:process];
	} else {
		NSLog(@"no process!?");
	}
	return list;
}

- (void)progress:(NSString *)aString;
{
	//	override to prevent reporting
}

@end
