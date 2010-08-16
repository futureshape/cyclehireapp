//
//  InfoViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 06/05/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "InfoViewController.h"

@implementation InfoViewController

static NSString *appFeedbackEmailTemplate = 
	@"Dear Cycle Hire App,<p>" \
	"<i>Write about your suggestions or issues here</i><p>" \
	"Thanks!<p>"\
	"P.S. I'm using Cycle Hire App on an %@ with software version %@";

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	if (self = [super initWithNibName:nibName bundle:nibBundle]) {
		self.tableViewStyle = UITableViewStyleGrouped;
		self.title = NSLocalizedString(@"About", nil);
		
		TTURLMap *map = [TTNavigator navigator].URLMap;
		[map from:@"cyclehire://information/feedback" toObject:self selector:@selector(appFeedback)];
		
		self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
						   NSLocalizedString(@"", nil),
						   [TTTableTextItem itemWithText:@"Your Cycle Hire account" URL:@"cyclehire://account/"],
						   NSLocalizedString(@"Help & Support", nil),
						   [TTTableButton itemWithText:NSLocalizedString(@"Send us your feedback", nil) 
												   URL:@"cyclehire://information/feedback"],
						   
						   NSLocalizedString(@"Acknowledgements", nil),
						   [TTTableSubtitleItem itemWithText:NSLocalizedString(@"Maps by OpenStreetMap",nil) 
													subtitle:NSLocalizedString(@"Under a CC-BY-SA 2.0 license", nil)
													imageURL:@"bundle://osm-logo.png" 
														 URL:@"http://www.openstreetmap.org/"],
						   [TTTableSubtitleItem itemWithText:NSLocalizedString(@"Directions by CycleStreets", nil) 
													subtitle:nil
													imageURL:@"bundle://cyclestreets-logo.png" 
														 URL:@"http://www.cyclestreets.net"],
						   [TTTableTextItem itemWithText:NSLocalizedString(@"More ...", nil) URL:@"http://cyclehireapp.com/acknowledgements.html"],
						   nil];
		
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;
		
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(didBecomeActive:) 
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
	
}


- (void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) didBecomeActive: (NSNotification *)notification {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
}

- (void) appFeedback {
	
	if(![MFMailComposeViewController canSendMail]) {
		UIAlertView *noMailAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No email available", nil) 
																message:NSLocalizedString(@"Email hasn't been set up on your device. Please use your computer to email your feedback to feedback@cyclehireapp.com", nil)   
															   delegate:nil 
													  cancelButtonTitle:NSLocalizedString(@"OK", nil) 
													  otherButtonTitles:nil];
		[noMailAlert show];
		[noMailAlert release];	
		return;
	}
	
	MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
	mailComposer.mailComposeDelegate = self;
	
	[mailComposer setSubject:@"Feedback for Cycle Hire app"];
	NSArray *toRecipients = [NSArray arrayWithObject:@"feedback@cyclehireapp.com"];
	[mailComposer setToRecipients:toRecipients];
	
	NSString *emailBody = [NSString stringWithFormat:appFeedbackEmailTemplate, 
						   [[UIDevice currentDevice] localizedModel], 
						   [[UIDevice currentDevice] systemVersion]];
	[mailComposer setMessageBody:emailBody isHTML:YES];
	
	[self presentModalViewController:mailComposer animated:YES];
	[mailComposer release];
}


- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error
{
    [self dismissModalViewControllerAnimated:YES];
	
	if (result == MFMailComposeResultSent) {
		UIAlertView *thankYouAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Thank you", nil) 
																message:NSLocalizedString(@"We review all suggestions and issues and will reply to your email if appropriate.", nil)   
															   delegate:nil 
													  cancelButtonTitle:NSLocalizedString(@"OK", nil) 
													  otherButtonTitles:nil];
		[thankYouAlert show];
		[thankYouAlert release];
	}	
}

@end
