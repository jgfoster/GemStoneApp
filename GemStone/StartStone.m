//
//  StartStone.m
//  GemStone
//
//  Created by James Foster on 7/3/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "StartStone.h"

@implementation StartStone

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			[database nameOrDefault],
			nil];
}

- (NSString *)currentDirectoryPath;
{
	return [database directory];
}

- (void)done;
{
	if ([errorOutput length]) {
		[super error:errorOutput];
	} else {
		[self notifyDone];
	}
}

- (NSMutableDictionary *)environment;
{
	NSString *directory = [database directory];
	NSString *config    = [NSString stringWithFormat:@"%@/conf/system.conf", directory];
	NSString *stoneLog  = [NSString stringWithFormat:@"\"%@/logs/%@.log\"", directory, [database nameOrDefault]];
	NSString *nrsString = [NSString stringWithFormat:@"#dir:%@#log:%@/logs/%%N_%%P.log", directory, directory];
	NSMutableDictionary *environment = [super environment];
	[environment setValue:[database gemstone] forKey:@"GEMSTONE"];
	[environment setValue:config    forKey:@"GEMSTONE_EXE_CONF"];
	[environment setValue:directory forKey:@"GEMSTONE_GLOBAL_DIR"];
	[environment setValue:stoneLog  forKey:@"GEMSTONE_LOG"];
	[environment setValue:nrsString forKey:@"GEMSTONE_NRS_ALL"];
	[environment setValue:config    forKey:@"GEMSTONE_SYS_CONF"];
//	[environment setValue:directory forKey:@"upgradeLogDir"];
	return environment;
}

- (void)error:(NSString *)aString;
{
	[errorOutput appendString:aString];
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/startstone", [database gemstone]];
}

- (void)setDatabase:(Database *)aDatabase;
{
	database = aDatabase;
}

@end
