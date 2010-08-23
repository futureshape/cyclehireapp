//
//  FavouritesListViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 28/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "FavouritesListViewController.h"

@implementation FavouritesListViewController

- (id)initWithName:(NSString*)name query:(NSDictionary*)query {
	if (self = [super init]) {
		self.title = NSLocalizedString(@"Favourites", nil);		
		CycleHireLocations *cycleHireLocations = (CycleHireLocations *)[query objectForKey:@"locations"];
		
		if([[cycleHireLocations favouriteLocations] count] > 0) {
			self.navigationItem.rightBarButtonItem = self.editButtonItem;
		}
		
		UISegmentedControl *favTypeSelection = [[UISegmentedControl alloc] init];
		[favTypeSelection insertSegmentWithTitle:@"Favourites" atIndex:0 animated:NO];
		[favTypeSelection insertSegmentWithTitle:@"Recent" atIndex:1 animated:NO];
		favTypeSelection.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		favTypeSelection.segmentedControlStyle = UISegmentedControlStyleBar;
		favTypeSelection.frame = CGRectMake(0, 0, 400, 30);
		favTypeSelection.selectedSegmentIndex = 0;
		[favTypeSelection addTarget:self action:@selector(favouritesTypeChanged:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.titleView = favTypeSelection;

		self.dataSource = [[[FavouritesListDataSource alloc] initWithCycleHireLocations:cycleHireLocations] autorelease];
		self.variableHeightRows = YES;
		
		TTNavigator *navigator = [TTNavigator navigator];
		TTURLMap *map = navigator.URLMap;
		[map removeObjectForURL:@"cyclehire://map/cycleHireLocation/(openCycleHireLocationWithId:)"]; 
		[map from:@"cyclehire://map/cycleHireLocation/(openCycleHireLocationWithId:)" 
			toObject:[map objectForURL:@"cyclehire://map/"]];
		
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(refreshData) 
												 name:LIVE_DATA_UPDATED_NOTIFICATION 
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(refreshData) 
												 name:LIVE_DATA_TOO_OLD_NOTIFICATION 
											   object:nil];
}

- (void) favouritesTypeChanged:(id)sender {
	UISegmentedControl *favTypeSelection = (UISegmentedControl *)sender;
	
	NSLog(@"Selected:%d", favTypeSelection.selectedSegmentIndex);
	self.editing = NO;
}

- (void) refreshData {
	[self.dataSource refreshData];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)model:(id<TTModel>)model didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
	[super model:model didDeleteObject:object atIndexPath:indexPath];
	NSLog(@"Delete:%d", indexPath.row);
}

@end
