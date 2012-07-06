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
	NSString *directory = [database directory];
	NSString *stoneLog  = [NSString stringWithFormat:@"%@/logs/%@.log", directory, [database nameOrDefault]];
	return [NSArray arrayWithObjects: 
			[database nameOrDefault],
			@"-l",
			stoneLog,
			nil];
}

- (NSString *)currentDirectoryPath;
{
	return [database directory];
}

- (void)data:(NSData *)data;
{
    NSString *string = [[NSString alloc] 
						initWithData:data 
						encoding:NSUTF8StringEncoding];
	NSLog(@"startstone data = %@", string);
}

- (void)done;
{
	NSLog(@"startstone is done!");
	[self notifyDone];
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

- (NSString *)launchPath;
{ 
	NSString *path = [NSString stringWithFormat:@"%@/bin/startstone", [database gemstone]];
	return path; 
}

- (void)setDatabase:(Database *)aDatabase;
{
	database = aDatabase;
}

@end
