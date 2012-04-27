//
//  Version.h
//  GemStone
//
//  Created by James Foster on 4/22/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Version : NSObject {
	BOOL		isInstalled;
	NSString	*version;
	NSDate		*date;
}

@property (readwrite,assign) BOOL		isInstalled;
@property (readwrite,retain) NSString	*version;
@property (readwrite,retain) NSDate		*date;

- (NSString *)dateString;
- (NSNumber *)isInstalledNumber;
- (NSString *)productPath;
- (BOOL)remove:(NSError **)error;
- (void)updateIsInstalled;
- (NSString *)zippedFileName;

@end
