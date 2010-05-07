//
//  LocationPopupViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 06/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "LocationPopupViewController.h"

@implementation LocationPopupViewController

static NSString *stationLocationFeedbackEmailTemplate = 
	@"Dear Cycle Hire App,<p>" \
	 "I think the map shows an incorrect location for this station: %@<p>" \
	 "Can you please check it?<p>" \
	 "Thanks!";

static NSString *stationBrokenFeedbackEmailTemplate = 
	@"Dear Cycle Hire App,<p>" \
	 "I think there's a fault at this station: %@<p>" \
	 "<i>Describe the fault here</i><p>" \
	 "Can you please check it?<p>" \
	 "Thanks!";

- (id)init {
	if (self = [super init]) {
		self.tableViewStyle = UITableViewStyleGrouped;
		self.variableHeightRows = YES;
		self.tableView.scrollEnabled = NO;
		self.tableView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
											UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	
		TTURLMap *map = [TTNavigator navigator].URLMap;
		[map from:@"cyclehire://location/report/" toObject:self selector:@selector(reportProblem)];
		[map from:@"cyclehire://map/from/(directionsFromLat:)/(Long:)" toObject:[map objectForURL:@"cyclehire://map/"]];
		[map from:@"cyclehire://map/to/(directionsToLat:)/(Long:)" toObject:[map objectForURL:@"cyclehire://map/"]];	
		[map from:@"cyclehire://location/favourite/" toObject:self selector:@selector(toggleFavourite)];
		
		locationTitleTableItem = [[TTTableStyledTextItem alloc] init];
		
		bikesAvailableTableItem = [[TTTableImageItem alloc] init];
		bikesAvailableTableItem.imageURL = @"bundle://bike-icon.png";
		
		spacesAvailableTableItem = [[TTTableImageItem alloc] init];
		spacesAvailableTableItem.imageURL = @"bundle://bike-parking.png";	
		
		directionsFromHereButton = [[TTTableButton alloc] init];
		directionsFromHereButton.text = NSLocalizedString(@"Directions from here", nil);
		
		directionsToHereButton = [[TTTableButton alloc] init];
		directionsToHereButton.text = NSLocalizedString(@"Directions to here", nil);
		
		addRemoveFavouritesButton = [[TTTableButton alloc] init];
		addRemoveFavouritesButton.URL = @"cyclehire://location/favourite/";
		
		reportProblemButton = [[TTTableButton alloc] init];
		reportProblemButton.text = NSLocalizedString(@"Report a problem", nil);
		reportProblemButton.URL = @"cyclehire://location/report/";
		
		self.dataSource = [TTSectionedDataSource dataSourceWithObjects:
						   @"",
						   locationTitleTableItem,
						   bikesAvailableTableItem,
						   spacesAvailableTableItem,
						   @"",
						   directionsFromHereButton,
						   directionsToHereButton,
						   addRemoveFavouritesButton,
						   reportProblemButton,
						   nil];
	}		

	return self;
}

- (void)updateForLocation:(CycleHireLocation *)location {
	
	currentCycleHireLocation = location;
	
	NSString *locationXHTML = [NSString 
							   stringWithFormat:@"<span class=\"locationText\">%@ <span class=\"redText\">%@</span></span>",
							   location.locationName, location.postcodeArea];
	locationTitleTableItem.text = [TTStyledText textFromXHTML:locationXHTML];
	
	bikesAvailableTableItem.text = [location localizedBikesAvailableText];

	spacesAvailableTableItem.text = [location localizedSpacesAvailableText];
	
	NSString *directionsFromURL = [NSString stringWithFormat:@"cyclehire://map/from/%f/%f", 
								 location.coordinate.latitude, location.coordinate.longitude];
	directionsFromHereButton.URL = directionsFromURL;
	
	NSString *directionsToURL = [NSString stringWithFormat:@"cyclehire://map/to/%f/%f", 
								 location.coordinate.latitude, location.coordinate.longitude];
	directionsToHereButton.URL = directionsToURL;
	
	[self updateFavouritesButton];
	
	[self.tableView reloadData];
}

- (void) reportProblem {
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"What kind of problem would you like to report?", nil) 
															 delegate:self 
													cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
											   destructiveButtonTitle:nil 
													otherButtonTitles:NSLocalizedString(@"Broken station or bike", nil),
																	  NSLocalizedString(@"Incorrect position on map", nil), nil];
	[actionSheet showInView:[[[TTNavigator navigator].URLMap objectForURL:@"cyclehire://map/"] mapView]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == actionSheet.cancelButtonIndex) return;
	
	MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
	mailComposer.mailComposeDelegate = self;
	
	if (buttonIndex == actionSheet.firstOtherButtonIndex) {
		// broken station - send to TfL
		[mailComposer setSubject:@"Cycle Hire Station Fault"];
		NSArray *toRecipients = [NSArray arrayWithObject:@"TfLFeedback@example.com"];
		[mailComposer setToRecipients:toRecipients];
		
		NSString *emailBody = [NSString stringWithFormat:stationBrokenFeedbackEmailTemplate, currentCycleHireLocation.locationName];
		[mailComposer setMessageBody:emailBody isHTML:YES];
	} else {
		// incorrect location - send to CHA
		[mailComposer setSubject:@"Incorrect position on map"];
		NSArray *toRecipients = [NSArray arrayWithObject:@"feedback@cyclehireapp.com"];
		[mailComposer setToRecipients:toRecipients];
		
		NSString *emailBody = [NSString stringWithFormat:stationLocationFeedbackEmailTemplate, currentCycleHireLocation.locationName];
		[mailComposer setMessageBody:emailBody isHTML:YES];
	}
	
	[[[TTNavigator navigator].URLMap objectForURL:@"cyclehire://map/"] presentModalViewController:mailComposer animated:YES];
	[mailComposer release];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error
{
    [[[TTNavigator navigator].URLMap objectForURL:@"cyclehire://map/"] dismissModalViewControllerAnimated:YES];
	
	if (result == MFMailComposeResultSent) {
		UIAlertView *thankYouAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Thanks for reporting this problem!", nil) 
																message:nil   
															   delegate:nil 
													  cancelButtonTitle:NSLocalizedString(@"OK", nil) 
													  otherButtonTitles:nil];
		[thankYouAlert show];
		[thankYouAlert release];
	}	
}

- (void) toggleFavourite {
	currentCycleHireLocation.favourite = !currentCycleHireLocation.favourite;
	
	[self updateFavouritesButton];
	[self.tableView reloadData];
}

- (void)updateFavouritesButton {
	NSString *favouritesButtonLabel = (currentCycleHireLocation.favourite ? 
									   NSLocalizedString(@"Remove from favourites", nil) : 
									   NSLocalizedString(@"Add to favourites", nil));
	addRemoveFavouritesButton.text = favouritesButtonLabel;	
}

- (void)dealloc {
    [super dealloc];
}

@end
