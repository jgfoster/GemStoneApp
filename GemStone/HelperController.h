//
//  HelperController.h
//  GemStone
//
//  Created by James Foster on 4/27/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Helper.h"

@interface HelperController : NSObject {
	IBOutlet NSTextField	*helperToolMessage;
	IBOutlet NSButton		*authenticateButton;
	
	Helper					*helper;
}

- (IBAction)installHelperTool:(id)sender;

@end
