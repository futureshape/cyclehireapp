//
//  AttractionListViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 28/03/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "AttractionListViewController.h"
#import	"MapViewController.h"

#import "parseCSV.h"

@implementation AttractionListViewController

static NSString *attractionsFeedbackEmailTemplate = 
		@"Dear Cycle Hire App,<p>" \
		"I think you should add the following attractions to the \"%@\" list:<p>" \
		"<i>Enter your suggestions here</i><p>" \
		"Thanks!";

- (id)initWithTitle: (NSString *) title attractionsCSV: (NSString *) csvFileName {
	if (self = [super init]) {
		self.title = NSLocalizedString(title,nil);
		
		CSVParser *parser = [CSVParser new];
		NSString *csvPath = [[NSBundle mainBundle] pathForResource:csvFileName ofType:nil]; 
		[parser openFile: csvPath];
		NSArray *attractions = [parser parseFile];
		[parser closeFile];
		
		NSMutableArray *titlesArray = [NSMutableArray arrayWithCapacity:attractions.count];
		for(NSArray *attractionRecord in attractions) {
			NSString *attractionName = [attractionRecord objectAtIndex:0];
			NSString *attractionURL = [NSString stringWithFormat:@"cyclehire://map/view/%@/%@/%@", 
									   [attractionRecord objectAtIndex:1],
									   [attractionRecord objectAtIndex:2],
									   [attractionRecord objectAtIndex:3]];
			[titlesArray addObject:[TTTableTextItem itemWithText:attractionName URL:attractionURL]];
		}

		TTListDataSource *attractionsDataSource = [TTListDataSource dataSourceWithItems:titlesArray];
		if([MFMailComposeViewController canSendMail]) {
			[attractionsDataSource.items addObject:[TTTableSubtitleItem  
														itemWithText:NSLocalizedString(@"Can't find what you're looking for?", nil) 
															subtitle:NSLocalizedString(@"Tell us what else should be in this list", nil)
																 URL:@"cyclehire://attractions/suggest/"]];
		}
		
		self.dataSource = attractionsDataSource;
		[parser release];
		
		TTNavigator *navigator = [TTNavigator navigator];
		TTURLMap *map = navigator.URLMap;
		[map removeObjectForURL:@"cyclehire://map/view/(centerOnLat:)/(Long:)/(withZoom:)"]; // just to be safe?
		[map from:@"cyclehire://map/view/(centerOnLat:)/(Long:)/(withZoom:)" 
			toObject:[map objectForURL:@"cyclehire://map/"]];
		
		[map removeObjectForURL:@"cyclehire://attractions/suggest/"];
		[map from:@"cyclehire://attractions/suggest/" toObject:self selector:@selector(attractionSuggest)];
	}
	return self;
}

- (void)attractionSuggest {
	MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
	mailComposer.mailComposeDelegate = self;
	
	[mailComposer setSubject:@"Attractions list suggestion"];
	NSArray *toRecipients = [NSArray arrayWithObject:@"feedback@cyclehireapp.com"];
	[mailComposer setToRecipients:toRecipients];
	
	NSString *emailBody = [NSString stringWithFormat:attractionsFeedbackEmailTemplate, self.title];
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
																message:NSLocalizedString(@"We'll check your suggestion and update this list in the next version of the Cycle Hire app", nil)   
															   delegate:nil 
													  cancelButtonTitle:NSLocalizedString(@"OK", nil) 
													  otherButtonTitles:nil];
		[thankYouAlert show];
		[thankYouAlert release];
	}	
}

- (void)dealloc {
    [super dealloc];
}

@end
