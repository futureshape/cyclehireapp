//
//  LocationPopupViewController.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 06/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Three20/Three20.h>

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "CycleHireLocation.h"

@interface LocationPopupViewController : TTTableViewController  <UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
	CycleHireLocation *currentCycleHireLocation;

	TTTableStyledTextItem *locationTitleTableItem; 
	TTTableImageItem *bikesAvailableTableItem;
	TTTableImageItem *spacesAvailableTableItem;

	TTTableButton *directionsFromHereButton;
	TTTableButton *directionsToHereButton;
	TTTableButton *addRemoveFavouritesButton;
	TTTableButton *reportProblemButton;	
}

- (void)updateForLocation:(CycleHireLocation *)location;

- (void)updateFavouritesButton;

@end
