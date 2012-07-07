//
//  Download.m
//  GemStone
//
//  Created by James Foster on 7/6/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Download.h"

@implementation Download

- (void)error:(NSString *)aString;
{
	[self progress:aString];
}

- (NSString *)launchPath;
{ 
	return @"/usr/bin/curl";
}

@end
