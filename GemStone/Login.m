//
//  Login.m
//  GemStone
//
//  Created by James Foster on 5/4/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "Login.h"


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
