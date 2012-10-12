//
//  Login.h
//  GemStone
//
//  Created by James Foster on 5/4/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Database.h"

@class Database; 

@interface Login : NSManagedObject {
	NSString * name;
	NSString * version;
	NSString * stoneHost;
	NSString * stoneName;
	NSNumber * gemTypeCode;	// 0 = RPC, 1 = linked
	NSString * gemHost;
	NSString * gemNet;
	NSString * gemTask;
	NSNumber * osTypeCode;	// 0 = guest, 1 = member
	NSString * osUser;
	NSString * osPassword;
	NSString * gsUser;
	NSString * gsPassword;
	NSString * developer;
	NSNumber * indexInArray;  
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * version;
@property (nonatomic, retain) NSString * stoneHost;
@property (nonatomic, retain) NSString * stoneName;
@property (nonatomic, retain) NSNumber * gemTypeCode;
@property (nonatomic, retain) NSString * gemHost;
@property (nonatomic, retain) NSString * gemNet;
@property (nonatomic, retain) NSString * gemTask;
@property (nonatomic, retain) NSNumber * osTypeCode;
@property (nonatomic, retain) NSString * osUser;
@property (nonatomic, retain) NSString * osPassword;
@property (nonatomic, retain) NSString * gsUser;
@property (nonatomic, retain) NSString * gsPassword;
@property (nonatomic, retain) NSString * developer;
@property (nonatomic, retain) NSNumber * indexInArray;  

- (void)initializeForDatabase:(Database *)aDatabase;
- (BOOL)isRpcGem;
- (BOOL)isOsGuest;
- (void)login;

@end
