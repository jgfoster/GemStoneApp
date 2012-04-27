//
//  VersionsController.h
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Versions.h"

@class Versions;

@interface VersionsController : NSWindowController {
	Versions *versions;
}

@property	Versions *versions;

@end
