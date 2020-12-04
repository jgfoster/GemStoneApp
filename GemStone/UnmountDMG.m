//
//  UnmountDMG.m
//  GemStone
//
//  Created by James Foster on 12/3/20.
//  Copyright © 2020 GemTalk Systems LLC. All rights reserved.
//

#import "AppController.h"
#import "UnmountDMG.h"
#import "Utilities.h"

@implementation UnmountDMG

- (NSArray *)arguments {
	return [NSArray arrayWithObjects:
			@"unmount",
			@"/Volumes/installGemStone/",
			nil];
}
- (void)done {
	[appController performSelectorOnMainThread:@selector(versionInstallDone:)
									withObject:self
								 waitUntilDone:NO];
	[super done];
}
- (NSString *)launchPath {
	return @"/usr/bin/hdiutil";
}

@end
