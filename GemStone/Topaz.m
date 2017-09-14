//
//  Topaz.m
//  GemStone
//
//  Created by James Foster on 7/16/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Topaz.h"
#import "Utilities.h"

@interface Topaz ()

@property	block_t		block;
@property	NSInteger	 session;

@end

@implementation Topaz

// @synthesize block;

+ (id)database:(Database *)aDatabase do:(block_t)aBlock;
{
	Topaz *instance = [super forDatabase:aDatabase];
	[instance setBlock:aBlock];
	return instance;
}

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			@"-l",
			nil];
}

- (NSString *)binName;
{
	return @"topaz";
}

- (void)cancel;
{
	if (self.session) {
		[self.task interrupt];	// sends SIGINT, equivalent of <Ctrl>+<C>
		[self send:@"logout\n"];
	}
	[self send:@"exit 1\n"];
	[self delayFor:1.0];	//	give time for a graceful exit
	[super cancel];
	[self doneWithError:0];
}

- (void)fullBackupTo:(NSString *)aString;
{
	if ([fileManager fileExistsAtPath:aString]) {
		NSError *error;
		[appController taskProgress:[NSString stringWithFormat:@"\nDeleting existing file at '%@'\n", aString]];
		BOOL flag = [fileManager removeItemAtPath:aString error:&error];
		if (flag == NO) {
			self.errorOutput = [NSMutableString stringWithFormat:@"Unable to delete %@ because %@\n", aString, [error description]];
			[self cancel];
			return;
		}
	}
	NSString *inString = [NSString
						  stringWithFormat:@"run\nSystemRepository fullBackupCompressedTo:'%@'\n%%\n", 
						  aString];
	[self progress:inString];
	NSString *outString = [self responseFrom:inString];
	if (![outString length]) {
		outString = [self outputUpToPrompt];
	}
	if ([outString rangeOfString:@"true\n"].location == NSNotFound) {
		self.errorOutput = [NSMutableString stringWithString:outString];
		[self cancel];
		return;
	}
	[self send:@"exit 0\n"];
	[appController taskFinishedAfterDelay];
}

- (NSString *)outputUpToPrompt;
{
	NSRange range0, range1, range2, range3;
	if ([[self.database version] isEqualTo:@"3.2.0"]) {
		[self send:@"\n"];
	}
	do {
		[self delayFor:0.01];
		NSInteger index = [self.standardOutput length] - 10;
		if (index < 0) index = 0;
		range0.location = index;
		range0.length = MIN([self.standardOutput length], 10);
		range1 = [self.standardOutput rangeOfString:@"topaz" options:0 range:range0];
		if (range1.location != NSNotFound) {
			range1.length = [self.standardOutput length] - range1.location;
			range2 = [self.standardOutput rangeOfString:@"> " options:0 range:range1];
		}
	} while (range1.location == NSNotFound || range2.location == NSNotFound || range1.location <= 1);
	range3.location = range1.location + 5;
	range3.length = range2.location - range3.location;
	if (range3.length) {
		range3.location = range3.location + 1;
		range3.length = range3.length - 1;
		self.session = [[self.standardOutput substringWithRange:range3] integerValue];
	} else {
		self.session = 0;
	}
	NSString *string = [self.standardOutput substringToIndex:range1.location];
	self.standardOutput = [NSMutableString new];
	return string;
}

- (NSString *)responseFrom:(NSString *)inString;
{
	[self send:inString];
	[self delayFor:1.0];
	return [self outputUpToPrompt];
}

- (void)restoreFromBackup:(NSString *)aString;
{
	NSString *inString = [NSString 
						  stringWithFormat:@"run\nSystemRepository restoreFromBackup:'%@'\n%%\n", 
						  aString];
	NSString *outString = [NSString stringWithFormat:@"%@ %@", [self responseFrom:inString], self.errorOutput];
	self.errorOutput = [NSMutableString new];
	self.standardOutput = [NSMutableString new];
	if ([outString isEqualToString:@" "]) {
		[self delayFor:1.0];
		outString = [self outputUpToPrompt];
		outString = [NSString stringWithFormat:@"%@ %@", outString, self.errorOutput];
		self.errorOutput = [NSMutableString new];
		self.standardOutput = [NSMutableString new];
	}
	NSRange range = [outString rangeOfString:@"The restore from full backup completed"];
	if (range.location == NSNotFound) {
		range = [outString rangeOfString:@"The restore from backup completed"];
	}
	if (range.location == NSNotFound) {
		self.errorOutput = [NSMutableString stringWithString:outString];
		[self cancel];
		return;
	}

	outString = [self responseFrom:@"login\n"];
	if (!self.session) {
		self.errorOutput = [NSMutableString stringWithString:[outString substringFromIndex:range.location]];
		[self cancel];
		return;
	}
	outString = [self responseFrom:@"run\nSystemRepository commitRestore\n%\n"];
	outString = [NSString stringWithFormat:@"%@ %@", outString, self.errorOutput];
	range = [outString rangeOfString:@"Restore from transaction log(s) succeeded"];
	if (self.session || range.location == NSNotFound) {
		self.errorOutput = [NSMutableString stringWithString:outString];
		[self cancel];
		return;
	}
	[self send:@"exit 0\n"];
}

- (void)send:(NSString *)inString;
{
	NSFileHandle *file = [[self.task standardInput] fileHandleForWriting];
	NSData *data = [inString dataUsingEncoding:NSUTF8StringEncoding];
	[file writeData:data];
}

- (void)startTask;
{
	[appController taskStart:[NSString stringWithFormat:@"Starting Topaz task...\n"]];
	[super startTask];
	[self outputUpToPrompt];
	if (self.session) {
		if (self.block) {
			self.block(self);
		}
	} else {
		self.errorOutput = [NSMutableString stringWithString:@"Topaz login was not successful!"];
		[self cancel];
	}
}

@end
