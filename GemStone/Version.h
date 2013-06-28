//
//  Version.h
//  GemStone
//
//  Created by James Foster on 4/22/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDownloadSite "http://seaside.gemtalksystems.com/downloads/i386.Darwin/"

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

+ (void)removeVersionAtPath:(NSString *)productPath;
- (BOOL)isInstalled;
- (NSString *)productPath;
- (void)remove;
- (void)updateIsInstalled;
- (NSString *)zippedFileName;

@end
