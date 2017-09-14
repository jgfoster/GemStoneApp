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
			self.path,
			nil];
}

- (NSString *)infoForPath:(NSString *)aString;
{
	self.path = aString;
	[self main];
	return self.allOutput;
}

- (NSString *)binName;
{ 
	return @"copydbf";
}

- (void)progress:(NSString *)aString;
{
	//	override to prevent reporting
}

@end
