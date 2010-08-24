//
//  FavouritesListViewController.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 28/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"

#import "FavouritesListDataSource.h"
#import "RecentDockingStationsDataSource.h"
#import "CycleHireLocations.h"

@interface FavouritesListViewController : TTTableViewController {

	FavouritesListDataSource *favouritesDataSource;
	RecentDockingStationsDataSource *recentsDataSource;
	
	UISegmentedControl *favTypeSelection;
}

- (void) refreshData;
- (void) favouritesTypeChanged:(id)sender;

@end
