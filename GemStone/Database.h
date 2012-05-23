//
//  Database.h
//  GemStone
//
//  Created by James Foster on 5/17/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Database : NSManagedObject {
	NSNumber *identifier;  
	NSNumber *indexInArray;  
	NSString *name;
	NSNumber *spc_mb;
	NSString *version;
}

@property (readonly)			NSNumber *identifier;  
@property (nonatomic, retain)	NSNumber *indexInArray;  
@property (nonatomic, retain)	NSString *name;
@property (nonatomic, retain)	NSNumber *spc_mb;
@property (nonatomic, retain)	NSString *version;

- (void)deleteAll;
- (void)installBaseExtent;
- (void)installGlassExtent;
- (BOOL)isRunning;
- (void)start;

@end
