//
//  Document.h
//  GemStone
//
//  Created by James Foster on 4/19/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Document : NSPersistentDocument {
	IBOutlet NSPopUpButton	*versionList;

	IBOutlet NSTextField	*stoneHostEntry;
	IBOutlet NSTextField	*stoneNameEntry;

	IBOutlet NSMatrix		*gemTypeMatrix;
	IBOutlet NSTextField	*gemHostLabel;
	IBOutlet NSTextField	*gemHostEntry;
	IBOutlet NSTextField	*gemNetLabel;
	IBOutlet NSTextField	*gemNetEntry;
	IBOutlet NSTextField	*gemTaskLabel;
	IBOutlet NSTextField	*gemTaskEntry;
	
	IBOutlet NSMatrix		*osTypeMatrix;
	IBOutlet NSTextField	*osUserLabel;
	IBOutlet NSTextField	*osUserEntry;
	IBOutlet NSTextField	*osPwdLabel;
	IBOutlet NSTextField	*osPwdEntry;
	
	IBOutlet NSTextField	*gsUserEntry;
	IBOutlet NSTextField	*gsPwdEntry;

	IBOutlet NSTextField	*developerEntry;
}

- (IBAction)login:(id)sender;
- (IBAction)setGemType:(id)sender;
- (IBAction)setOsType:(id)sender;

@end
