//
//  Login.h
//  GemStone
//
//  Created by James Foster on 5/4/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Login : NSManagedObject

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

- (BOOL)isRpcGem;
- (BOOL)isOsGuest;
- (void)login;

@end
