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

-(id) init {
	if (self = [super init]) {
		self.tableViewStyle = UITableViewStyleGrouped;
		self.title = NSLocalizedString(@"About", nil);
		
		TTURLMap *map = [TTNavigator navigator].URLMap;
		[map from:@"cyclehire://information/feedback" toObject:self selector:@selector(appFeedback)];
		
		self.dataSource = [TTSectionedDataSource dataSourceWithObjects:NSLocalizedString(@"Acknowledgements", nil),
						   [TTTableSubtitleItem itemWithText:NSLocalizedString(@"Maps by OpenStreetMap",nil) 
													subtitle:NSLocalizedString(@"Under a CC-BY-SA 2.0 license", nil)
													imageURL:@"bundle://osm-logo.png" 
														 URL:@"http://www.openstreetmap.org/"],
						   [TTTableSubtitleItem itemWithText:NSLocalizedString(@"Directions by CycleStreets", nil) 
													subtitle:nil
													imageURL:@"bundle://cyclestreets-logo.png" 
														 URL:@"http://www.cyclestreets.net"],
						   [TTTableTextItem itemWithText:NSLocalizedString(@"More ...", nil) URL:@"bundle://acknowledgements.html"],
						   NSLocalizedString(@"Links", nil),
						   [TTTableSubtitleItem itemWithText:NSLocalizedString(@"Cycle Hire App website", nil) 
													subtitle:nil
													imageURL:@"bundle://cyclehireapp-logo.png"  
														 URL:@"http://cyclehireapp.com/"],
						   [TTTableSubtitleItem itemWithText:NSLocalizedString(@"TfL Cycle Hire website", nil)
													subtitle:NSLocalizedString(@"Official Cycle Hire scheme website", nil)
													imageURL:@"bundle://tfl-cyclehire-logo.png"  
														 URL:@"http://www.tfl.gov.uk/cyclehire"],
						   @"",
						   [TTTableButton itemWithText:NSLocalizedString(@"Send us your feedback", nil) 
												   URL:@"cyclehire://information/feedback"],
						   nil];
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;
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
