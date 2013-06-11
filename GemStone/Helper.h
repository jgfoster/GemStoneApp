//
//  Helper.h
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helper : NSObject
- (void)ensureSharedMemoryMB:(NSNumber *)sizeMB;
- (void)install;
- (BOOL)isCurrent;
- (void)remove;
@end
