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
		scraper = [[AccountScraper alloc] init];
		scraper.delegate = self;
		
		self.variableHeightRows = YES;
		
		df = [[NSDateFormatter alloc] init];
		[df setDateFormat:@"EEE dd MMM yyyy - HH:mm"];
	}
	return self;
}

- (void) viewDidAppear:(BOOL)animated {
	if ([[NSUserDefaults standardUserDefaults] objectForKey:kEmailKey] == nil) {
		[self setupForLogin];
	} else {
		self.title = @"Your account";
		if([self.dataSource isKindOfClass:[TTTableViewInterstitialDataSource class]]) { 
			self.dataSource = [TTListDataSource dataSourceWithObjects:[TTTableTextItem itemWithText:@" "], nil];
		}
		[self loadAccountInformation]; 
	}
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
	passwordField.text = @"";
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

	[self loadAccountInformation];
}

- (void) loadAccountInformation {
	if(hud == nil) { 
		hud = [[MBProgressHUD alloc] initWithView:self.view];
	}
	
	[self.view addSubview:hud];
	hud.labelText = @"Loading";
	[hud show:YES]; 

	[scraper startScraping];
}

- (void) scraperDidFailWithError:(NSError *)error {	
	[hud hide:YES];
	[hud removeFromSuperview];
	
	if ([[error domain] isEqualToString:kAccountScraperErrorDomain]) {
		if ([error code] == kASNoCsrfError) {
			[[[[UIAlertView alloc] initWithTitle:@"Can't connect to the Cycle Hire website" 
										 message:@"Please try again later. (Error code: CSRF)"
										delegate:nil 
							   cancelButtonTitle:@"OK" 
							   otherButtonTitles:nil] autorelease] show]; 
		} else if ([error code] == kASLoginFailedError) {
			[[[[UIAlertView alloc] initWithTitle:@"Login failed" 
										 message:@"Please check your username & password and try again"
										delegate:nil 
							   cancelButtonTitle:@"OK" 
							   otherButtonTitles:nil] autorelease] show];
			[self setupForLogin];
		} else if ([error code] == kASParsingFailed) {
			[self switchToTableViewStyle:UITableViewStyleGrouped];
			self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
							   NSLocalizedString(@"", nil),
							   [TTTableTextItem itemWithText:@"Can't process account information"],
							   [TTTableGrayTextItem itemWithText:@"If this problem persists, please contact feedback@cyclehireapp.com."],
							   NSLocalizedString(@"", nil),
							   [TTTableButton itemWithText:@"Retry" delegate:self selector:@selector(loadAccountInformation)],
							   nil];
		}
	} else {
		[self switchToTableViewStyle:UITableViewStyleGrouped];
		self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
						   NSLocalizedString(@"", nil),
						   [TTTableTextItem itemWithText:@"Can't connect to the Cycle Hire website"],
						   [TTTableGrayTextItem itemWithText:[error localizedDescription]],
						   NSLocalizedString(@"", nil),
						   [TTTableButton itemWithText:@"Retry" delegate:self selector:@selector(loadAccountInformation)],
						   nil];
	}
}

- (void) scraperDidFinishScraping {
	NSArray *journeyLog = scraper.journeyLog;
	
	NSMutableArray *activityItems = [NSMutableArray arrayWithCapacity:[scraper.journeyLog count]];
	
	for (JourneyLogEntry *entry in journeyLog) {
		NSDateComponents *tripDurationComps = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit
																			  fromDate:entry.startDate 
																				toDate:entry.endDate
																			   options:0];
		NSString *tripDuration = ([tripDurationComps hour] == 0 ?
								  [NSString stringWithFormat:@"%d mins", [tripDurationComps minute]] :
								  [NSString stringWithFormat:@"%d hr %d mins", [tripDurationComps hour], [tripDurationComps minute]]);
		
		NSString *journeyDescription = [NSString stringWithFormat:@"%C %@\n%C %@\n%C %@ - %C%@", 
										0x2190, entry.startStation, 
										0x2192, entry.endStation,
										0x231A, tripDuration,
										0x00A3, entry.cost];  
		[activityItems addObject:[TTTableSubtextItem itemWithText:[df stringFromDate:entry.startDate] caption:journeyDescription]];			
	}

	NSMutableArray *accountInfoItems = [NSMutableArray arrayWithCapacity:1];
	NSString *balanceFormatted = [NSString stringWithFormat:@"Balance: %C%@", 0x00A3, scraper.accountBalance];
	[accountInfoItems addObject:[TTTableTextItem itemWithText:balanceFormatted]];
	
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
						   [TTTableButton itemWithText:@"Reload" delegate:self selector:@selector(loadAccountInformation)],
						   nil];
	} else {
		[self switchToTableViewStyle:UITableViewStylePlain];
		
		NSMutableArray *statsItems = [NSMutableArray arrayWithCapacity:2];
		[statsItems addObject:
		 [TTTableTextItem itemWithText:
		  [NSString stringWithFormat:@"%d cycle hire journeys", [activityItems count]]]];
		[statsItems addObject:
		 [TTTableTextItem itemWithText:
		  [NSString stringWithFormat:@"%@ of cycling", [self formattedTimeFromInterval:scraper.totalCyclingTime]]]];
		[statsItems addObject:
		 [TTTableTextItem itemWithText:
		  [NSString stringWithFormat:@"%d docking stations visited", [scraper.uniqueDockingStationsVisited count]]]];
				
		self.dataSource = [TTSectionedDataSource dataSourceWithArrays:@"Account status", accountInfoItems,
						   @"Statistics", statsItems,
						   @"Journey history", activityItems, nil];
		
	}
	
	[hud hide:YES];
	[hud removeFromSuperview];
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
	[scraper stopScraping];
}

- (NSString *) formattedTimeFromInterval: (NSTimeInterval) interval {
	NSDate *fakeStartDate = [NSDate date];
	NSDate *fakeEndDate = [fakeStartDate dateByAddingTimeInterval:interval];
	NSDateComponents *totalTimeComps = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit
																	   fromDate:fakeStartDate
																		 toDate:fakeEndDate
																		options:0];
	NSMutableString *totalTimeFormatted = [NSMutableString string];
	
	NSInteger days = [totalTimeComps day];
	NSInteger hours = [totalTimeComps hour];
	NSInteger minutes = [totalTimeComps minute];

	if (days > 0) {
		[totalTimeFormatted appendFormat:@"%d day%@%@ ", days, (days == 1 ? @"" : @"s"), (minutes == 0 || hours == 0 ? @" and" : @",")];
	}
	
	if (hours > 0) {
		[totalTimeFormatted appendFormat:@"%d hour%@ ", hours, (hours == 1 ? @"" : @"s")];
	}
	
	if (minutes > 0) {
		[totalTimeFormatted appendFormat:@"%@ %d minute%@", (hours == 0 ? @"" : @"and"), minutes, (minutes == 1 ? @"" : @"s")];
	}
	
	return totalTimeFormatted;
}

- (void) dealloc {
	[super dealloc];
	[emailField release];
	[passwordField release];
	[scraper release];
	[df release];
}

@end
