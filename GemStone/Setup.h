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

@property (nonatomic, retain) NSNumber	*lastDatabaseIdentifier;
@property (nonatomic, retain) NSNumber	*taskCloseWhenDoneCode;
@property (nonatomic, retain) NSDate	*versionsDownloadDate;

- (NSNumber *)newDatabaseIdentifier;

@end
