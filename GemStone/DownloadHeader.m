//
//  DownloadHeader.m
//  GemStone
//
//  Created by James Foster on 12/3/20.
//  Copyright © 2020 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadHeader.h"
#import "Utilities.h"

@implementation DownloadHeader

@synthesize contentLength = _contentLength;
@synthesize resultCode = _resultCode;
@synthesize url = _url;

- (NSArray *)arguments {
	return [NSArray arrayWithObjects:
			@"-I",
			self.url,
			nil];
}

- (void)dataString:(NSString *)aString {
	[self.standardOutput appendString:aString];
}

- (void)done {
	NSString *string = self.standardOutput;
	NSArray *lines = [string componentsSeparatedByString:@"\r\n"];
	NSArray *fields = [lines[0] componentsSeparatedByString:@" "];
	self.resultCode = [fields[1] integerValue];
	self.contentLength = -1;
	for (id line in lines) {
		fields = [line componentsSeparatedByString:@": "];
		if ([fields[0] isEqualToString:@"Content-Length"]) {
			self.contentLength = [fields[1] integerValue];
			break;
		}
	}
	self.standardOutput = nil;
}

@end
