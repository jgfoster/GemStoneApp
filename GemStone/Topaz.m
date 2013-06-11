//
//  Topaz.m
//  GemStone
//
//  Created by James Foster on 7/16/12.
//  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.
//

#import "Topaz.h"
#import "Utilities.h"

@implementation Topaz

@synthesize login;
@synthesize block;

+ (id)login:(Login *)aLogin toDatabase:(Database *)aDatabase andDo:(block_t)aBlock;
{
	Topaz *instance = [super forDatabase:aDatabase];
	[instance setLogin:aLogin];
	[instance setBlock:aBlock];
	return instance;
}

- (NSArray *)arguments;
{ 
	return [NSArray arrayWithObjects: 
			@"-l",
			nil];
}

- (void)cancel;
{
	if (session) {
		[task interrupt];	// sends SIGINT, equivalent of <Ctrl>+<C>
		[self send:@"logout\n"];
	}
	[self send:@"exit 1\n"];
	[super cancel];
}

- (void)dataString:(NSString *)aString;
{
	[standardOutput appendString:aString];
	[super dataString:aString];
}

- (void)fullBackupTo:(NSString *)aString;
{
	[appController taskStart:[NSString stringWithFormat:@"\n\n"]];
	if ([fileManager fileExistsAtPath:aString]) {
		NSError *error;
		[appController taskProgress:[NSString stringWithFormat:@"Deleting existing file at '%@'\n", aString]];
		BOOL flag = [fileManager removeItemAtPath:aString error:&error];
		if (flag == NO) {
			errorOutput = [NSMutableString stringWithFormat:@"Unable to delete %@ because %@\n", aString, [error description]];
			[self cancel];
			[self doneWithError:0];
			return;
		}
	}
	NSString *inString = [NSString 
						  stringWithFormat:@"run\nSystemRepository fullBackupCompressedTo:'%@'\n%%\n", 
						  aString];
	[appController taskProgress:inString];
	NSString *outString = [self responseFrom:inString];
	if (![outString length]) {
		outString = [self outputUpToPrompt];
	}
	if (![outString isEqualToString:@"true\n"]) {
		errorOutput = [NSMutableString stringWithString:outString];
		[self cancel];
		[self doneWithError:0];
	}
	[self send:@"exit 0\n"];
	[appController taskFinishedAfterDelay];
}

- (NSString *)launchPath;
{ 
	return [NSString stringWithFormat:@"%@/bin/topaz", [database gemstone]];
}

- (NSString *)outputUpToPrompt;
{
	NSRange range0, range1, range2, range3;
	do {
		[self doRunLoopFor:0.01];
		NSInteger index = [standardOutput length] - 10;
		if (index < 0) index = 0;
		range0.location = index;
		range0.length = MIN([standardOutput length], 10);
		range1 = [standardOutput rangeOfString:@"topaz" options:0 range:range0];
		if (range1.location != NSNotFound) {
			range1.length = [standardOutput length] - range1.location;
			range2 = [standardOutput rangeOfString:@"> " options:0 range:range1];
		}
	} while (range1.location == NSNotFound || range2.location == NSNotFound);
	range3.location = range1.location + 5;
	range3.length = range2.location - range3.location;
	if (range3.length) {
		range3.location = range3.location + 1;
		range3.length = range3.length - 1;
		session = [[standardOutput substringWithRange:range3] integerValue]; 
	} else {
		session = 0;
	}
	NSString *string = [standardOutput substringToIndex:range1.location];
	standardOutput = [NSMutableString new];
	return string;
}

- (NSString *)responseFrom:(NSString *)inString;
{
	[self send:inString];
	return [self outputUpToPrompt];
}

- (void)restoreFromBackup:(NSString *)aString;
{
	NSString *inString = [NSString 
						  stringWithFormat:@"run\nSystemRepository restoreFromBackup:'%@'\n%%\n", 
						  aString];
	NSString *outString = [self responseFrom:inString];
	if (![outString length]) {
		outString = [self outputUpToPrompt];
	}
	NSRange range = [outString rangeOfString:@"The restore from full backup completed"];
	
	if (range.location == NSNotFound) {
		range = [outString rangeOfString:@"The restore from backup completed"];
	}
	if (range.location == NSNotFound) {
		errorOutput = [NSMutableString stringWithString:outString];
		[self doneWithError:0];
		[self cancel];
		return;
	}

	outString = [self responseFrom:@"login\n"];
	if (!session) {
		errorOutput = [NSMutableString stringWithString:[outString substringFromIndex:range.location]];
		[self doneWithError:0];
		[self cancel];
		return;
	}
	outString = [self responseFrom:@"run\nSystemRepository commitRestore\n%\n"];
	if (![outString length]) {
		outString = [self outputUpToPrompt];
	}
	range = [outString rangeOfString:@"Restore from transaction log(s) succeeded"];
	if (session || range.location == NSNotFound) {
		errorOutput = [NSMutableString stringWithString:outString];
		[self doneWithError:0];
		[self cancel];
		return;
	}
	[self send:@"exit 0\n"];
}

- (void)send:(NSString *)inString;
{
	[[[task standardInput] fileHandleForWriting] writeData:[inString dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)startTask;
{
	[super startTask];
	[self outputUpToPrompt];
	NSString *inString = [NSString 
						stringWithFormat:@"set user %@ password %@ gemstone %@\n", 
						[login gsUser], 
						[login gsPassword],
						[login stoneName]];
	NSString *outString = [self responseFrom:inString];
	outString = [self responseFrom:@"login\n"];
	if (session) {
		if (block) {
			block(self);
		}
		return;
	}
	NSString *expect = @"GemStone: Error";
	NSRange range = [outString rangeOfString:expect];
	if (range.location == NSNotFound) {
		range.location = MAX([outString length] - 200, 0);
	}
	errorOutput = [NSMutableString stringWithString:[outString substringFromIndex:range.location]];
	[self doneWithError:0];
	[self cancel];
}

@end
