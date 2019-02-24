//
//  Download.m
//  GemStone
//
//  Created by James Foster on 7/6/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Download.h"
#import "Utilities.h"

@implementation Download

- (void)errorOutputString:(NSString *)aString {
	[self progress:aString];
	// no need to send super since we don't need to save output
}

- (NSString *)launchPath;
{ 
	return @"/usr/bin/curl";
}

@end
