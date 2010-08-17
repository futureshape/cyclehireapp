//
//  AccountViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 11/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "AccountViewController.h"

@implementation AccountViewController

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	if (self = [super initWithNibName:nibName bundle:nibBundle]) {
		self.variableHeightRows = YES;

		requestQueue = [[ASINetworkQueue alloc] init];
		
		df = [[NSDateFormatter alloc] init];
		[df setDateFormat:@"dd MMM yyyy HH:mm"];
		[df setLenient:YES];
		
		if ([[NSUserDefaults standardUserDefaults] objectForKey:kEmailKey] == nil) {
			[self setupForLogin];
		} else {
			self.title = @"Your account";
			self.dataSource = [TTListDataSource dataSourceWithObjects:[TTTableTextItem itemWithText:@" "], nil];
			[self loadCycleHireLoginPage]; 
		}
	}
	return self;
}

- (void) setupForLogin {
	[self switchToTableViewStyle:UITableViewStyleGrouped];
	
	self.title = NSLocalizedString(@"Account login", nil);
	
	if(emailField == nil) {
		emailField = [[UITextField alloc] init];
	}
	emailField.placeholder = @"Email address";
	emailField.text = [[NSUserDefaults standardUserDefaults] objectForKey:kEmailKey];
	emailField.keyboardType = UIKeyboardTypeEmailAddress;
	emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	emailField.autocorrectionType = UITextAutocorrectionTypeNo;
	emailField.returnKeyType = UIReturnKeyNext;
	emailField.delegate = self;
	
	if (passwordField == nil) {
		passwordField = [[UITextField alloc] init];
	}
	passwordField.placeholder = @"Password";
	passwordField.secureTextEntry = YES;
	passwordField.returnKeyType = UIReturnKeyGo;
	passwordField.delegate = self;
	
	self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
					   NSLocalizedString(@"", nil),
					   emailField,
					   passwordField,
					   NSLocalizedString(@"", nil),
					   [TTTableButton itemWithText:@"Login" delegate:self selector:@selector(loginButtonTapped)],
					   NSLocalizedString(@"", nil),
					   [TTTableGrayTextItem itemWithText:@"Note: This is the same username & password that you use for the Cycle Hire website."],
					   nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	if(textField == emailField) {
		[passwordField becomeFirstResponder];
	} else if (textField == passwordField) {
		NSLog(@"Here");
		[self loginButtonTapped];
	}
	return NO;
}

- (void) loginButtonTapped {
	[emailField resignFirstResponder];
	[passwordField resignFirstResponder];
	
	BOOL emailMissing = [emailField.text length] == 0;
	BOOL passwordMissing = [passwordField.text length] == 0;
	
	if (emailMissing || passwordMissing) {
		[[[[UIAlertView alloc] initWithTitle:@"Login details missing" 
									 message:@"Please enter both your email adddress and password to continue" 
									delegate:nil 
						   cancelButtonTitle:@"OK" 
						   otherButtonTitles:nil] autorelease] show];
	
		return;
	}	
	
	NSString *email = emailField.text;
	NSString *password = passwordField.text;
	
	[[NSUserDefaults standardUserDefaults] setObject:email forKey:kEmailKey];
	[[NSUserDefaults standardUserDefaults] setObject:password forKey:kPasswordKey];

	[self loadCycleHireLoginPage];
}

- (void) loadCycleHireLoginPage {
	hud = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:hud];
	hud.labelText = @"Logging in";
	[hud show:YES]; 
		
	NSLog(@"Loading homepage");	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:CYCLE_HIRE_LOGIN_PAGE]];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(loadingHomepageFinished:)];
	[requestQueue addOperation:request];
	[requestQueue go];
}

- (void)loadingHomepageFinished:(ASIHTTPRequest *)_request{
	NSLog(@"Homepage loaded");
	NSString *responseString = [_request responseString];
	
	NSArray *captureComponents = [responseString arrayOfCaptureComponentsMatchedByRegex:CSRF_REGEX];
	
	if([captureComponents count] > 0 && 
	   [[captureComponents objectAtIndex:0] count] == 2 &&
	   ![[[captureComponents objectAtIndex:0] objectAtIndex:1] isEqualToString:@""]) {
		NSString *CSRF = [[captureComponents objectAtIndex:0] objectAtIndex:1];
		NSLog(@"Found CSRF token: %@", CSRF);
		[self sendLoginRequestWithCSRF:CSRF];
	} else {
		[hud setHidden:YES];
		[[[[UIAlertView alloc] initWithTitle:@"Can't connect to the Cycle Hire website" 
									 message:@"Please try again later. (Error code: CSRF)"
									delegate:nil 
						   cancelButtonTitle:@"OK" 
						   otherButtonTitles:nil] autorelease] show]; 
	}
}

- (void)requestFailed:(ASIHTTPRequest *)_request {
	NSError *error = _request.error;
	
	[hud setHidden:YES];
	[self switchToTableViewStyle:UITableViewStyleGrouped];
	self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
					   NSLocalizedString(@"", nil),
					   [TTTableTextItem itemWithText:@"Can't connect to the Cycle Hire website"],
					   [TTTableGrayTextItem itemWithText:[error localizedDescription]],
					   NSLocalizedString(@"", nil),
					   [TTTableButton itemWithText:@"Retry" delegate:self selector:@selector(loadCycleHireLoginPage)],
					   nil];
}

- (void) sendLoginRequestWithCSRF: (NSString *) CSRF {
	NSLog(@"Logging in");

	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:CYCLE_HIRE_LOGIN_PAGE]];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(loginRequestFinished:)];
	[request setPostValue:[[NSUserDefaults standardUserDefaults] objectForKey:kEmailKey] forKey:@"login[Email]"]; 
	[request setPostValue:[[NSUserDefaults standardUserDefaults] objectForKey:kPasswordKey] forKey:@"login[Password]"];
	[request setPostValue:CSRF forKey:@"login[_csrf_token]"];
	[requestQueue addOperation:request];
	[requestQueue go];
}

- (void)loginRequestFinished:(ASIHTTPRequest *)_request{
	NSString *postLoginURL = [_request.url absoluteString];
	NSLog(@"Login request finished on page: %@", postLoginURL);
	
	if ([postLoginURL isEqualToString:CYCLE_HIRE_ACCOUNT_HOME]) {
		// login worked 
		[self loadCycleHireActivityLog];
	} else {
		// have been redirected somewhere else - error (most likely wrong password - extract?)
		[hud setHidden:YES];
		[[[[UIAlertView alloc] initWithTitle:@"Login failed" 
									 message:@"Please check your username & password and try again"
									delegate:nil 
						   cancelButtonTitle:@"OK" 
						   otherButtonTitles:nil] autorelease] show];
		[self setupForLogin];
	}
}	
		 
- (void) loadCycleHireActivityLog {
	hud.labelText = @"Downloading";
	NSLog(@"Loading activity log");	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:CYCLE_HIRE_ACTIVITY_LOG]];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(loadingActivityLogFinished:)];
	[requestQueue addOperation:request];
	[requestQueue go];
}
		 
- (void)loadingActivityLogFinished:(ASIHTTPRequest *)_request{
	hud.labelText = @"Processing";
	NSLog(@"Activity log loaded");
	NSString *responseString = [_request responseString];
	
	@try {
		NSArray *split1 = [responseString componentsSeparatedByString:@"<tbody>"];
		NSArray *split2 = [[split1 objectAtIndex:1] componentsSeparatedByString:@"</tbody>"];
		NSString *tableString = [split2 objectAtIndex:0];
		NSMutableString *tableString2 = [NSMutableString stringWithFormat:@"<tbody>%@</tbody>", tableString];
		[tableString2 replaceOccurrencesOfString:@"&pound;"
									  withString:@""
										 options:NSCaseInsensitiveSearch
										   range:NSMakeRange(0, [tableString2 length])];
		[tableString2 replaceOccurrencesOfString:@"<br/>"
									  withString:@" "
										 options:NSCaseInsensitiveSearch
										   range:NSMakeRange(0, [tableString2 length])];
		TTXMLParser *parser = [[TTXMLParser alloc] initWithData:[tableString2 dataUsingEncoding:NSUTF8StringEncoding]];
		[parser setTreatDuplicateKeysAsArrayItems:YES];
		[parser parse];
		
		NSArray *rows = [parser.rootObject objectForKey:@"tr"];
		
		NSMutableArray *activityItems = [NSMutableArray arrayWithCapacity:[rows count]];
		NSMutableArray *accountInfoItems = [NSMutableArray arrayWithCapacity:1];
		
		for (NSDictionary *rowEntry in rows) {
			NSArray *rowCells = [rowEntry objectForKey:@"td"];
			
			if ([rowCells count] == 6) {
				NSString *eventType = [[[rowCells objectAtIndex:4] objectForXMLNode] stringByTrimmingCharactersInSet:
									   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				if ([[eventType lowercaseString] isEqualToString:@"hire"]) {
					NSString *startDateString = [[[rowCells objectAtIndex:0] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSString *endDateString	  = [[[rowCells objectAtIndex:1] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSString *startStation	  = [[[rowCells objectAtIndex:2] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSString *endStation	  = [[[rowCells objectAtIndex:3] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSString *cost			  = [[[rowCells objectAtIndex:5] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					
					NSDate *startDate = [df dateFromString:startDateString];
					NSDate *endDate = [df dateFromString:endDateString];
					
					NSDateComponents *tripDurationComps = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit
																						  fromDate:startDate 
																							toDate:endDate 
																						   options:0];
					NSString *tripDuration = ([tripDurationComps hour] == 0 ?
											  [NSString stringWithFormat:@"%d mins", [tripDurationComps minute]] :
											  [NSString stringWithFormat:@"%d hr %d mins", [tripDurationComps hour], [tripDurationComps minute]]);
					
					NSString *journeyDescription = [NSString stringWithFormat:@"%C %@\n%C %@\n%C %@ - %C%@", 
													0x2190, startStation, 
													0x2192, endStation,
													0x231A, tripDuration,
													0x00A3, cost];  
					[activityItems addObject:[TTTableSubtextItem itemWithText:startDateString caption:journeyDescription]];			
				}
			} else if ([rowCells count] == 3) {
				NSString *eventType = [[[rowCells objectAtIndex:1] objectForXMLNode] stringByTrimmingCharactersInSet:
									   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				if ([[eventType lowercaseString] isEqualToString:@"balance"]) {
					NSString *balance = [[[rowCells objectAtIndex:2] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					
					if (balance != nil) {
						NSString *balanceFormatted = [NSString stringWithFormat:@"Balance: %C%@", 0x00A3, balance];
						[accountInfoItems addObject:[TTTableTextItem itemWithText:balanceFormatted]];
					}
				}
			}
		}

		UIBarButtonItem *logoutButton = [[[UIBarButtonItem alloc] initWithTitle:@"Logout" 
																		  style:UIBarButtonItemStyleBordered 
																		 target:self 
																		 action:@selector(logout)] autorelease];
		self.navigationItem.rightBarButtonItem = logoutButton; 		
		self.title = @"Your account";
		
		if([activityItems count] == 0) {
			[self switchToTableViewStyle:UITableViewStyleGrouped];
			self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
							   @"",
							   [TTTableTextItem itemWithText:@"No journeys on your account"],
							   [TTTableGrayTextItem itemWithText:@"If you've made journeys and can see them on the Cycle Hire website, please report this problem to feedback@cyclehireapp.com"],
							   @"",
							   [TTTableButton itemWithText:@"Reload" delegate:self selector:@selector(loadCycleHireLoginPage)],
							   nil];
		} else {
			[self switchToTableViewStyle:UITableViewStylePlain];
			
			self.dataSource = [TTSectionedDataSource dataSourceWithArrays:@"Account status", accountInfoItems, @"Journey history", activityItems, nil];
		}

	}
	@catch (NSException *exception) {
		// Something went wrong with the parsing above - not much we can do about it
		NSString *errorDescription = 
			[NSString stringWithFormat:@"If this problem persists, please contact feedback@cyclehireapp.com. (Exception: %@, Reason:%@)", 
			 [exception name], [exception reason]];
		
		self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
						   NSLocalizedString(@"", nil),
						   [TTTableTextItem itemWithText:@"Can't process account information"],
						   [TTTableGrayTextItem itemWithText:errorDescription],
						   NSLocalizedString(@"", nil),
						   [TTTableButton itemWithText:@"Retry" delegate:self selector:@selector(loadCycleHireLoginPage)],
						   nil];
	}
	@finally {
		[hud hide:YES];
	}
}	

- (void) logout {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kEmailKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kPasswordKey];
	self.navigationItem.rightBarButtonItem = nil;
	[self setupForLogin];
}

- (void) switchToTableViewStyle: (UITableViewStyle) style {
	self.tableView = nil;
	self.tableViewStyle = style;
	[self tableView];
}

- (void) viewWillDisappear:(BOOL)animated {
	[requestQueue cancelAllOperations];
}

- (void) dealloc {
	[super dealloc];
	[requestQueue release];
	[emailField release];
	[passwordField release];
	[df release];
}

@end
