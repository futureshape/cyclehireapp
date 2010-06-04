//
//  InfoWebViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 06/05/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "InfoWebViewController.h"

@implementation InfoWebViewController

- (void)openURL:(NSURL*)URL {
	NSLog(@"InfoWebViewController openURL:%@", [URL description]);
	
	if([[URL scheme] isEqualToString:@"bundle"]) {
		NSString *strippedURL = [[URL absoluteString] substringFromIndex:9];
		NSString *filePathInBundle = [[NSBundle mainBundle] pathForResource:strippedURL ofType:nil];
		NSURL *fileURL = [NSURL fileURLWithPath:filePathInBundle];
		[super openURL:fileURL];
	} else {
		[super openURL:URL];
	}
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request
 navigationType:(UIWebViewNavigationType)navigationType {
	if ([[request.URL scheme] isEqualToString:@"http"]) {
		[[UIApplication sharedApplication] openURL:request.URL];
		return NO;
	}
	return [super webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

@end
