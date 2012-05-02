//
//  VersionsController.h
//  GemStone
//
//  Created by James Foster on 4/20/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TaskProgressController.h"
#import "Versions.h"

@class Versions;

@interface VersionsController : NSObject <NSOpenSavePanelDelegate> {
	IBOutlet TaskProgressController	*taskProgressController;
	IBOutlet NSTextField			*dateField;
	IBOutlet NSTableView			*versionsTable;
	
	Versions						*versions;
}

- (IBAction)importVersion:(id)sender;
- (IBAction)updateVersions:(id)sender;

@end
