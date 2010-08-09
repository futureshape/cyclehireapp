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
#import "CycleHireLocations.h"

@interface LocationPopupViewController : TTTableViewController  <UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
	CycleHireLocation *currentCycleHireLocation;

	TTTableSubtitleItem *locationTitleTableItem;
	TTTableImageItem *bikesAvailableTableItem;
	TTTableImageItem *spacesAvailableTableItem;
	TTTableImageItem *bikesCapacityTableItem;

	TTTableButton *directionsFromHereButton;
	TTTableButton *directionsToHereButton;
	TTTableButton *addRemoveFavouritesButton;
	TTTableButton *reportProblemButton;	
}

- (void)updateForLocation:(CycleHireLocation *)location withFreshData:(BOOL)freshData;

- (void)updateFavouritesButton;

@end
