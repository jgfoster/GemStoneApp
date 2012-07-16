//
//  Login.m
//  GemStone
//
//  Created by James Foster on 5/4/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Login.h"
#import "Utilities.h"


@implementation Login

@dynamic name;
@dynamic version;
@dynamic stoneHost;
@dynamic stoneName;
@dynamic gemTypeCode;
@dynamic gemHost;
@dynamic gemNet;
@dynamic gemTask;
@dynamic osTypeCode;
@dynamic osUser;
@dynamic osPassword;
@dynamic gsUser;
@dynamic gsPassword;
@dynamic developer;
@dynamic indexInArray;

- (void)initializeForDatabase:(Database *)aDatabase;
{
	name = @"Default login";
	version = [aDatabase version];
	stoneHost = @"localhost";
	stoneName = [aDatabase name];
	gemTypeCode = 0;
	gemHost = @"localhost";
	gemNet = [NSString stringWithFormat:@"!tcp@localhost#netldi:%@#task!gemnetobject", [aDatabase netLDI]];
	gemTask = @"gemnetobject";
	osTypeCode = 0;
	gsUser = @"DataCurator";
	gsPassword = @"swordfish";
	developer = NSUserName();
}

- (BOOL)isRpcGem;
{
	return ![self.gemTypeCode boolValue];
}

- (BOOL)isOsGuest;
{
	return ![self.osTypeCode boolValue];
}

- (void)login;
{
	NSLog(@"login");
}

@end
