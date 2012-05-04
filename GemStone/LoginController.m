//
//  LoginController.m
//  GemStone
//
//  Created by James Foster on 4/30/12.
//  Copyright (c) 2012 VMware Inc. All rights reserved.
//

#import "LoginController.h"

@implementation LoginController

@synthesize currentLogin;

- (void)awakeFromNib;
{
	[self setGemType:nil];
	[self setOsType:nil];
	currentLogin = [Login new];
}

- (IBAction)deleteEntry:(id)sender;
{
	NSLog(@"deleteEntry:");
}

- (IBAction)login:(id)sender;
{
	NSLog(@"login:");
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
{
	NSLog(@"LoginController-numberOfRowsInTableView");
	return 0;
}

- (IBAction)saveEntry:(id)sender;
{
	NSLog(@"saveEntry:");
}

- (IBAction)setGemType:(id)sender;
{
	NSString *identifier = [[gemTypeMatrix selectedCell] identifier];
	BOOL hidden = [identifier compare:@"linkedGem"] == NSOrderedSame;
	[gemHostLabel setHidden:hidden];
	[gemHostEntry setHidden:hidden];
	[gemNetLabel  setHidden:hidden];
	[gemNetEntry  setHidden:hidden];
	[gemTaskLabel setHidden:hidden];
	[gemTaskEntry setHidden:hidden];
}

- (IBAction)setOsType:(id)sender;
{
	NSString *identifier = [[osTypeMatrix selectedCell] identifier];
	BOOL hidden = [identifier compare:@"osGuest"] == NSOrderedSame;
	[osUserLabel setHidden:hidden];
	[osUserEntry setHidden:hidden];
	[osPwdLabel  setHidden:hidden];
	[osPwdEntry  setHidden:hidden];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
{
	return nil;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors;
{
	return;
}

@end
