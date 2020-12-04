//
//  UnzipVersion.m
//  GemStone
//
//  Created by James Foster on 9/19/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "AppController.h"
#import "UnzipVersion.h"
#import "Utilities.h"

@implementation UnzipVersion

- (NSArray *)arguments {
	if (!self.filePath) AppError(@"Zip file path must be provided!");
	return [NSArray arrayWithObjects:
			self.filePath,
			@"-d",
			basePath,
			nil];
}

- (void)cancel {
	[super cancel];
}

- (void)done {
	if ([self.filePath hasPrefix:basePath]) {
		[fileManager removeItemAtPath:self.filePath error:nil];
	}
	[super done];
}

- (NSString *)launchPath {
	return @"/usr/bin/unzip";
}

@end
