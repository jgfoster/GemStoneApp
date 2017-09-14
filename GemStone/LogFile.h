//
//  LogFile.h
//  GemStone
//
//  Created by James Foster on 7/11/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LogFile : NSObject { }

@property (readonly)	NSString	*path;
@property (readonly)	NSString	*type;
@property (readonly)	NSString	*pid;
@property (readonly)	NSDate		*date;
@property (readonly)	NSNumber	*size;

+ (LogFile *)logFileFromDictionary:(NSDictionary *)aDictionary;

- (void)open;

@end
