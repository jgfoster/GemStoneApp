//
//  GSList.m
//  GemStone
//
//  Created by James Foster on 7/10/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "GSList.h"

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
			@"-l",
			nil];
}

- (void)dataString:(NSString *)aString;
{
	[standardOutput appendString:aString];
//	NSLog(@"stdout: %@", aString);		
}

- (void)done;
{
	NSLog(@"%@", standardOutput);
/*
gslist[Info]: No GemStone servers.
--- or ---
Status   Version    Owner    Pid   Port   Started     Type       Name
------- --------- --------- ----- ----- ------------ ------      ----
  OK    3.1.0     jfoster    1029 44485 Jul 10 09:26 Netldi      44485
  OK    3.1.0     jfoster    1129  5830 Jul 10 09:30 Netldi      5830
  OK    3.1.0     jfoster     530 49932 Jul 10 08:57 Stone       gs64stone
  OK    3.1.0     jfoster     531 49924 Jul 10 08:57 cache       gs64stone~3fdedd382a86f539
*/
}

- (void)doneWithError:(int)statusCode;
{
	NSLog(@"errout: %@", errorOutput);
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/gslist", [database gemstone]];
}

- (NSArray *)processList;
{
	NSMutableArray *list = [NSMutableArray new];
	NSLog(@"before");
	[self run];
	NSLog(@"after");
	return list;
}

@end
