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
			@"http://seaside.gemstone.com/downloads/i386.Darwin/",
			nil];
}

- (void)dataString:(NSString *)aString { 
	
}

- (void)done;
{
	NSString *string = standardOutput;
	standardOutput = nil;
	if (!task) return;		// task cancelled!
	task = nil;
	
	NSUInteger loc = [string rangeOfString:@">"].location;
	if (NSNotFound == loc) {
		NSLog(@"invalid data returned from version list");
		[self notifyDone];
		return;
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
		NSLog(@"error parsing version list HTML: %@", [error description]);
		[self notifyDone];
		return;
	}
	NSArray *nodes = [doc nodesForXPath:@"/html/body/table/tr" error:&error];
	NSRange nodeRange = {3, [nodes count] - 4};
	nodes = [nodes subarrayWithRange:nodeRange];
	
	NSDateFormatter *inFormatter = [NSDateFormatter new];
	[inFormatter setDateFormat:@"dd-MMM-yyyy hh:mm"];
	NSDateFormatter *outFormatter = [NSDateFormatter new];
	[outFormatter setDateFormat:@"yyyy-mm-dd"];
	versions = [NSMutableArray arrayWithCapacity:[nodes count]];
	for (id node in nodes) {
		NSArray *fields = [node nodesForXPath:@"td" error:&error];
		NSString *name = [[fields objectAtIndex:1] stringValue];
		NSDate   *date = [inFormatter dateFromString:[[fields objectAtIndex:2] stringValue]];
		NSRange  range = {13, [name length] - 29};
		name = [name substringWithRange:range];
		NSDictionary *version = [NSMutableDictionary dictionaryWithCapacity:3];
		[version setValue:name forKey:@"name"];
		[version setValue:date forKey:@"date"];
		[versions addObject:version];
	}
	[self notifyDone];
}

@end
