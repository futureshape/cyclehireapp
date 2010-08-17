//
//  AccountViewController.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 11/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Three20/Three20.h"
#import <extThree20XML/extThree20XML.h>

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "MBProgressHUD.h"

#define CYCLE_HIRE_LOGIN_PAGE		@"https://web.barclayscyclehire.tfl.gov.uk/"
#define CYCLE_HIRE_ACCOUNT_HOME		@"https://web.barclayscyclehire.tfl.gov.uk/account/home"
#define CYCLE_HIRE_ACTIVITY_LOG		@"https://web.barclayscyclehire.tfl.gov.uk/account/activity"
#define CSRF_REGEX					@"value=\"([a-fA-F\\d]{32})\""
#define kEmailKey					@"CycleHireEmail"
#define kPasswordKey				@"CycleHirePassword"

@interface AccountViewController : TTTableViewController <UITextFieldDelegate> {

	UITextField *emailField;
	UITextField *passwordField;
	
	ASINetworkQueue *requestQueue;
	
	MBProgressHUD *hud;
	NSDateFormatter *df;
}

- (void) setupForLogin;
- (void) loadCycleHireLoginPage;
- (void) loginButtonTapped;
- (void) sendLoginRequestWithCSRF: (NSString *)CSRF;
- (void) loadCycleHireActivityLog;
- (void) switchToTableViewStyle: (UITableViewStyle) style;
@end
