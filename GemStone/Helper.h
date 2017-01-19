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

@property (readonly)	BOOL	isAvailable;

- (void)ensureSharedMemory;
- (void)install;
- (void)remove;
- (void)terminate;
@end
