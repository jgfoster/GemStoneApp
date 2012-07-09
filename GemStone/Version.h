//
//  Version.h
//  GemStone
//
//  Created by James Foster on 4/22/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDownloadRequest @"downloadRequest"
#define kRemoveRequest @"removeVersionRequest"
#define kRemoveVersionDone @"removeVersionDone"

@interface Version : NSManagedObject {
	NSNumber	*isInstalledCode;
	NSString	*name;
	NSDate		*date;
	
	NSTask		*task;
}

@property (nonatomic, retain) NSNumber	*isInstalledCode;
@property (nonatomic, retain) NSString	*name;
@property (nonatomic, retain) NSDate	*date;
@property (nonatomic, retain) NSNumber	*indexInArray;  

- (BOOL)isInstalled;
- (NSString *)productPath;
- (void)remove;
- (void)updateIsInstalled;
- (NSString *)zippedFileName;

@end
