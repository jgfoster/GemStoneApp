//
//  DownloadVersionList.m
//  GemStone
//
//  Created by James Foster on 5/7/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//
//	Note that this is expecting a very specific format (from lighttp)

#import "DownloadVersionList.h"
#import "Utilities.h"
#import "Version.h"

@implementation DownloadVersionList

@synthesize versions = _versions;

- (NSArray *)arguments;
{
	return [NSArray arrayWithObjects:
			@kDownloadSite,
			nil];
}

- (void)dataString:(NSString *)aString;
{
	[self.standardOutput appendString:aString];
}

- (void)done;
{
	NSString *string = self.standardOutput;
	self.standardOutput = nil;
	NSUInteger loc = [string rangeOfString:@">"].location;
	if (NSNotFound == loc) {
		AppError(@"invalid data returned from version list");
	}
	string = [NSString stringWithFormat:@"%@%@",
			  @"<?xml version='1.0' encoding='UTF-8' ?",
			  [string substringFromIndex:loc]];
	string = [string stringByReplacingOccurrencesOfString:@"]\">" withString:@"]\" />"];
	string = [string stringByReplacingOccurrencesOfString:@"<hr>" withString:@"<hr />"];
	string = [string stringByReplacingOccurrencesOfString:@"&nbsp" withString:@""];
	NSError *error = nil;
	NSXMLDocument *doc = [[NSXMLDocument new] initWithXMLString:string options:0 error:&error];
	if (error) {
		AppError(@"error parsing version list HTML: %@", [error description]);
	}
	NSArray *nodes = [doc nodesForXPath:@"/html/body/div/table/tbody/tr" error:&error];
	NSRange nodeRange = {1, [nodes count] - 1};
	nodes = [nodes subarrayWithRange:nodeRange];
	NSDateFormatter *inFormatter = [NSDateFormatter new];
	[inFormatter setDateFormat:@"yyyy-MMM-dd hh:mm:ss"];
	NSDateFormatter *outFormatter = [NSDateFormatter new];
	[outFormatter setDateFormat:@"yyyy-mm-dd"];
	_versions = [NSMutableArray arrayWithCapacity:[nodes count]];
	for (id node in nodes) {
		NSArray *fields = [node nodesForXPath:@"td" error:&error];
		NSString *name = [[fields objectAtIndex:0] stringValue];
		NSDate   *date = [inFormatter dateFromString:[[fields objectAtIndex:1] stringValue]];
		NSRange  range = {13, [name length] - 29};
		name = [name substringWithRange:range];
		NSDictionary *version = [NSMutableDictionary dictionaryWithCapacity:3];
		[version setValue:name forKey:@"name"];
		[version setValue:date forKey:@"date"];
		[self.versions addObject:version];
	}
	[super done];
}

@end
