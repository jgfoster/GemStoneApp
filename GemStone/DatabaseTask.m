//
//  DatabaseTask.m
//  GemStone
//
//  Created by James Foster on 7/9/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "DatabaseTask.h"
#import "Utilities.h"

@implementation DatabaseTask

+ (id)forDatabase:(Database *)aDatabase {
	DatabaseTask *instance = [self new];
	[instance setDatabase:aDatabase];
	return instance;
}

- (NSString *)binName {
	mustOverride();
	return @"";
}

- (NSString *)currentDirectoryPath {
	return [self.database directory];
}

- (NSMutableDictionary *)environment {
	NSString *directory = [self.database directory];
	NSString *config    = [NSString stringWithFormat:@"%@/conf", directory];
	NSString *stoneLog  = [NSString stringWithFormat:@"%@/log/%@.log", directory, [self.database name]];
	NSString *nrsString = [NSString stringWithFormat:@"#netldi:%@#dir:%@#log:%@/log/%%N_%%P.log", 
						   [self.database netLDI], directory, directory];
	nrsString = [nrsString stringByReplacingOccurrencesOfString:@" " withString:@"^ "];
	NSMutableDictionary *environment = [super environment];
	[environment setValue:[self.database gemstone] forKey:@"GEMSTONE"];
	[environment setValue:config    forKey:@"GEMSTONE_EXE_CONF"];
	[environment setValue:directory forKey:@"GEMSTONE_GLOBAL_DIR"];
	[environment setValue:stoneLog  forKey:@"GEMSTONE_LOG"];
	[environment setValue:nrsString forKey:@"GEMSTONE_NRS_ALL"];
	[environment setValue:config    forKey:@"GEMSTONE_SYS_CONF"];
	//	[environment setValue:directory forKey:@"upgradeLogDir"];
	return environment;
}

- (NSString *)launchPath {
	return [NSString stringWithFormat:@"%@/bin/%@", [self.database gemstone], [self binName]];
}

@end
