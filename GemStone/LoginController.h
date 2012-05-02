//
//  LoginController.h
//  GemStone
//
//  Created by James Foster on 4/30/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LoginController : NSObject {
	IBOutlet NSTextField	*name;
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

- (IBAction)deleteEntry:(id)sender;
- (IBAction)login:(id)sender;
- (IBAction)saveEntry:(id)sender;
- (IBAction)setGemType:(id)sender;
- (IBAction)setOsType:(id)sender;

@end
