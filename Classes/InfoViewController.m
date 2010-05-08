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
	"Thanks!";

-(id) init {
	if (self = [super init]) {
		self.tableViewStyle = UITableViewStyleGrouped;
		self.title = NSLocalizedString(@"About", nil);
		
		TTURLMap *map = [TTNavigator navigator].URLMap;
		[map from:@"cyclehire://information/feedback" toObject:self selector:@selector(appFeedback)];

		
		self.dataSource = [TTSectionedDataSource dataSourceWithObjects:@"Acknowledgements",
						   [TTTableSubtitleItem itemWithText:@"Maps by OpenStreetMap" 
													subtitle:@"Under a CC-BY-SA 2.0 license"
													imageURL:@"bundle://cycle-hire-icon.png" 
														 URL:@"http://www.openstreetmap.org/"],
						   [TTTableSubtitleItem itemWithText:@"Directions by CycleStreets" 
													subtitle:nil
													imageURL:@"bundle://cycle-hire-icon.png" 
														 URL:@"http://www.cyclestreets.net"],
						   [TTTableTextItem itemWithText:NSLocalizedString(@"More ...", nil) URL:@"bundle://acknowledgements.html"],
						   @"",
						   [TTTableButton itemWithText:NSLocalizedString(@"Send us your feedback", nil) URL:@"cyclehire://information/feedback"],
						   nil];
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;
}

- (void) appFeedback {
	MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
	mailComposer.mailComposeDelegate = self;
	
	[mailComposer setSubject:@"Feedback for Cycle Hire app"];
	NSArray *toRecipients = [NSArray arrayWithObject:@"feedback@cyclehireapp.com"];
	[mailComposer setToRecipients:toRecipients];
	
	NSString *emailBody = appFeedbackEmailTemplate;
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
