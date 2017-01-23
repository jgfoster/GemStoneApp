//
//  Helper.h
//  GemStone
//
//  Created by James Foster on 15-Jan-2017.
//  Copyright (c) 2017 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helper : NSObject {
    xpc_connection_t    connection;
}

@property (readonly)	BOOL		hasDNS;
@property (readonly)	NSString	*ipAddress;
@property (readonly)	BOOL		isAvailable;

- (void)addToEtcHosts;
- (void)checkDNS;
- (void)ensureSharedMemory;
- (NSString*) hostName;
- (void)install;
- (void)remove;
- (NSString *)shmall;
- (NSString *)shmmax;
- (void)terminate;
@end
