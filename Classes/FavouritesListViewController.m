//
//  FavouritesListViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 28/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "FavouritesListViewController.h"

@implementation FavouritesListViewController

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle {
	if (self = [super initWithNibName:nibName bundle:nibBundle]) {
		self.title = NSLocalizedString(@"Favourites", nil);		
		favouritesDataSource = [[FavouritesListDataSource alloc] init];
		recentsDataSource = [[RecentDockingStationsDataSource alloc] init];
		
		favTypeSelection = [[UISegmentedControl alloc] init];
		[favTypeSelection insertSegmentWithTitle:@"Favourites" atIndex:0 animated:NO];
		[favTypeSelection insertSegmentWithTitle:@"Recent" atIndex:1 animated:NO];
		favTypeSelection.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		favTypeSelection.segmentedControlStyle = UISegmentedControlStyleBar;
		favTypeSelection.frame = CGRectMake(0, 0, 400, 30);
		favTypeSelection.selectedSegmentIndex = 0;
		[favTypeSelection addTarget:self action:@selector(favouritesTypeChanged:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.titleView = favTypeSelection;
		self.variableHeightRows = YES;
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
		
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
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(recentsLoaded) 
												 name:RECENTS_UPDATED_NOTIFICATION 
											   object:nil];
	
	[self favouritesTypeChanged:nil];
}

- (void) favouritesTypeChanged:(id)sender {
	self.editing = NO;
	[self invalidateModel];
	if (favTypeSelection.selectedSegmentIndex == 0) {
		self.dataSource = favouritesDataSource;
		self.navigationItem.rightBarButtonItem.enabled = 
			([[[CycleHireLocations sharedCycleHireLocations] favouriteLocations] count] > 0);
	} else {
		self.dataSource = recentsDataSource;
		self.navigationItem.rightBarButtonItem.enabled = NO;
		if([[CycleHireLocations sharedCycleHireLocations] updateRecentlyUsedDockingStations]) {
			recentsDataSource.updating = YES;
		}
	}
	[self refreshData];
}

- (void) refreshData {
	[self.dataSource refreshData];
	[self.tableView reloadData];
}

- (void) recentsLoaded {
	recentsDataSource.updating = NO;
	if (favTypeSelection.selectedSegmentIndex == 1) {
		[self invalidateModel];
		self.dataSource = recentsDataSource;
		self.navigationItem.rightBarButtonItem.enabled = NO;
		[self refreshData];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)model:(id<TTModel>)model didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
	[super model:model didDeleteObject:object atIndexPath:indexPath];
	NSLog(@"Delete:%d", indexPath.row);
	self.navigationItem.rightBarButtonItem.enabled = 
		([[[CycleHireLocations sharedCycleHireLocations] favouriteLocations] count] > 0);
}

- (void)dealloc {
	[super dealloc];
	[favouritesDataSource release];
	[recentsDataSource release];	
	[favTypeSelection release];
}

@end
