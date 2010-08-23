//
//  AccountViewController.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 11/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Three20/Three20.h"
#import "MBProgressHUD.h"

#import "AccountScraper.h"

@interface AccountViewController : TTTableViewController <UITextFieldDelegate, AccountScraperDelegate> {

	UITextField *emailField;
	UITextField *passwordField;
		
	MBProgressHUD *hud;
	
	AccountScraper *scraper;
}

- (void) setupForLogin;
- (void) loadAccountInformation;
- (void) loginButtonTapped;
- (void) switchToTableViewStyle: (UITableViewStyle) style;
- (NSString *) formattedTimeFromInterval: (NSTimeInterval) interval;
@end
