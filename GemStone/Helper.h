//
//  Helper.h
//  GemStone
//
//  Created by James Foster on 15-Jan-2017.
//  Copyright (c) 2017 GemTalk Systems LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helper : NSObject {
    xpc_connection_t connection;
}
- (void)ensureSharedMemory;
- (void)install;
- (BOOL)isCurrent;
- (void)remove;
- (void)terminate;
@end
