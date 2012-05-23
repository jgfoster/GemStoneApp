//
//  Setup.h
//  GemStone
//
//  Created by James Foster on 5/22/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Setup : NSManagedObject

@property (nonatomic, retain) NSDate * versionsDownloadDate;
@property (nonatomic, retain) NSNumber * lastDatabaseIdentifier;

- (NSNumber *)newDatabaseIdentifier;

@end
