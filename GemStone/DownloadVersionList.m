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

- (NSArray *)arguments {
	return [NSArray arrayWithObjects:
			@kDownloadSite,
			nil];
}

- (void)dataString:(NSString *)aString {
	[self.standardOutput appendString:aString];
}

- (void)done {
	NSString *string = self.standardOutput;
	self.standardOutput = nil;
	string = [NSString stringWithFormat:@"%@%@",
			  @"<?xml version='1.0' encoding='UTF-8' ?>",
			  string];
	string = [string stringByReplacingOccurrencesOfString:@"]\">" withString:@"]\" />"];
	string = [string stringByReplacingOccurrencesOfString:@"<hr>" withString:@"<hr />"];
	string = [string stringByReplacingOccurrencesOfString:@"&nbsp" withString:@""];
	NSError *error = nil;
	NSXMLDocument *doc = [[NSXMLDocument new] initWithXMLString:string options:0 error:&error];
	if (error) {
		AppError(@"error parsing version list HTML: %@", [error description]);
	}
	NSArray *nodes = [doc nodesForXPath:@"/html/body/pre" error:&error];
    if (error) {
        AppError(@"error parsing version list node: %@", [error description]);
    }
    nodes = [[nodes objectAtIndex:0] children];
    NSRange nodeRange = {1, [nodes count] - 1};
    nodes = [nodes subarrayWithRange:nodeRange];
   	NSDateFormatter *inFormatter = [NSDateFormatter new];
	[inFormatter setDateFormat:@"dd-MMM-yyyy"];
	NSDateFormatter *outFormatter = [NSDateFormatter new];
	[outFormatter setDateFormat:@"yyyy-mm-dd"];
	_versions = [NSMutableArray arrayWithCapacity:[nodes count] / 2];
    for (int i = 0; i < [nodes count]; i += 2) {
        NSString *name = [[[nodes objectAtIndex:i] attributeForName:@"href"] stringValue];
        NSRange  range = {13, [name length] - 29};
        name = [name substringWithRange:range];
        NSString *data = [[nodes objectAtIndex:i + 1] stringValue];
        NSArray *fields = [data componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        fields = [fields filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        NSDate *date = [inFormatter dateFromString:[fields objectAtIndex:0]];
		NSDictionary *version = [NSMutableDictionary dictionaryWithCapacity:2];
		[version setValue:name forKey:@"name"];
		[version setValue:date forKey:@"date"];
		[self.versions addObject:version];
	}
	[super done];
}

@end
