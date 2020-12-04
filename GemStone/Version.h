//
//  Version.h
//  GemStone
//
//  Created by James Foster on 4/22/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDownloadSite "https://downloads.gemtalksystems.com/platforms/i386.Darwin/"

@interface Version : NSManagedObject {
	NSNumber	*_isInstalledCode;
	NSTask		*task;
}

@property				NSDate		*date;
@property				NSNumber	*indexInArray;
@property (readonly)	BOOL		isInstalled;
@property				NSNumber	*isInstalledCode;
@property				NSString	*name;

+ (void)removeVersionAtPath:(NSString *)productPath;
- (BOOL)isInstalled;
- (NSString *)productPath;
- (void)remove;
- (void)updateIsInstalled;

@end
