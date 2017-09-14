//
//  Terminal.m
//  GemStone
//
//  Created by James Foster on 9/24/13.
//  Copyright (c) 2013 VMware Inc. All rights reserved.
//

#import "Terminal.h"
#import "Utilities.h"

@interface Terminal ()

@property	NSString *script;

@end

@implementation Terminal

+ (void)doScript:(NSString *)script forDatabase:(Database *)aDatabase;
{
	Terminal *terminal = [super forDatabase:aDatabase];
	[terminal setScript:script];
	[appController addOperation:terminal];
}

- (NSArray *)arguments;
{
	NSMutableString *string = [NSMutableString new];
	[string appendString:@"#!/bin/sh\n"];
	[string appendString:@"# set environment variables for GemStone/S\n"];
	[string appendFormat: @"cd %@\n", [self.database directory]];
	NSDictionary *environment = [self environment];
	for (NSString* key in [environment allKeys]) {
		if ([key rangeOfString:@"GEM"].location != NSNotFound) {
			[string appendFormat:@"export %@=\'%@\'\n", key, [environment valueForKey:key]];
		}
	}
	[string appendString:@"export PATH=\"$GEMSTONE/bin:$GEMSTONE/seaside/bin:$PATH\"\n"];
	[string appendString:@"export DYLD_LIBRARY_PATH=\"$GEMSTONE/lib:$DYLD_LIBRARY_PATH\"\n"];
	[string appendString:@"export MANPATH=\"$GEMSTONE/doc:$MANPATH\"\n"];
	[string appendString:@"# from $GEMSTONE/seaside/etc/gemstone.conf\n"];
	[string appendFormat:@"export GEMSTONE_USER=\"%@\"\n", NSUserName()];
	[string appendFormat:@"export GEMSTONE_NAME=\"%@\"\n", [self.database name]];
	[string appendFormat:@"export GEMSTONE_LOGDIR=\"%@/log\"\n", [self.database directory]];
	[string appendFormat:@"export GEMSTONE_DATADIR=\"%@/data\"\n", [self.database directory]];
	
	[string appendFormat:@"# rm %@\n", [self scriptPath]];
	[string appendFormat:@"%@\n", self.script];
	NSNumber *number = [NSNumber numberWithShort:0700];
	NSDictionary *attributes = [NSDictionary dictionaryWithObject:number
														   forKey:NSFilePosixPermissions];
	if (![fileManager
		  createFileAtPath:[self scriptPath]
		  contents:[string dataUsingEncoding:NSUTF8StringEncoding]
		  attributes:attributes]) {
		AppError(@"Unable to create file at %@", [self scriptPath]);
	};
	string = [NSMutableString stringWithFormat:@"do script \"source \'%@\'\"", [self scriptPath]];
	return [NSArray arrayWithObjects:
			@"-e",
			@"tell application \"Terminal\"",
			@"-e",
			@"activate",
			@"-e",
			@"tell window 1",
			@"-e",
			string,
			@"-e",
			@"end tell",
			@"-e",
			@"end tell",
			@"-e",
			@"delay 10",
			nil];
}

- (NSMutableDictionary *)environment;
{
	NSMutableDictionary *environment = [super environment];
	for (NSString* key in [environment allKeys]) {
		if ([key rangeOfString:@"DYLD_"].location != NSNotFound) {
			[environment removeObjectForKey:key];
		}
	}
	return environment;
}

- (NSString *)launchPath;
{
	return @"/usr/bin/osascript";
}

- (NSString *)scriptPath;
{
	return [NSString stringWithFormat:@"%@/setEnv.sh", [self.database directory]];
}

@end
