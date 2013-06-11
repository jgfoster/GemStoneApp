//
//  CopyDBF.m
//  GemStone
//
//  Created by James Foster on 7/12/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "CopyDBF.h"

@implementation CopyDBF

+ (NSString *)infoForFile:(NSString *)aString in:(Database *)aDatabase;
{
	CopyDBF *instance = [self forDatabase:aDatabase];
	NSString *path = [NSString stringWithFormat:@"%@/data/%@", [aDatabase directory], aString];
	return [instance infoForPath:path];
}

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			@"-I",
			path,
			nil];
}

- (void)dataString:(NSString *)aString;
{
//	useful output goes to stderr!
}

- (void)errorOutputString:(NSString *)aString;
{
	[errorOutput appendString:aString];
}

- (NSString *)infoForPath:(NSString *)aString;
{
	path = aString;
	[self main];
	return errorOutput;
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/copydbf", [database gemstone]];
}

@end
