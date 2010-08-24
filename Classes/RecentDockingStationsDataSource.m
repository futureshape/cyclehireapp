//
//  RecentDockingStationsDataSource.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 23/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "RecentDockingStationsDataSource.h"

@implementation RecentDockingStationsDataSource

@synthesize updating;

- (id)init {
	if (self = [super init]) {
		[self refreshData];
	}
	return self;
}

-(void) refreshData {
	CycleHireLocations *chLocations = [CycleHireLocations sharedCycleHireLocations];
	[self.items removeAllObjects];
	if(self.updating) {
		[self.items insertObject:[TTTableActivityItem itemWithText:@"Refreshing recent locations"] atIndex:0];
	}
	for (CycleHireLocation *location in chLocations.recentlyUsedDockingStations) {
		[self.items addObject:[self tableItemForLocation:location]];
	}	
}

-(TTTableItem*) tableItemForLocation:(CycleHireLocation*)location {
	NSString *title = [NSString stringWithFormat:@"%@, %@", location.locationName, location.villageName];
	
	NSString *subtitle;
	if ([[CycleHireLocations sharedCycleHireLocations] freshDataAvailable]) {
		subtitle = [NSString stringWithFormat:@"%@, %@", 
					[location localizedBikesAvailableText], 
					[location localizedSpacesAvailableText]];
	} else {
		subtitle = [location localizedCapacityText];
	}
	
	NSString *URL = [NSString stringWithFormat:@"cyclehire://map/cycleHireLocation/%@", location.locationId];
	return [TTTableSubtitleItem itemWithText:title subtitle:subtitle URL:URL];
}

- (UIImage*)imageForEmpty {
	return TTIMAGE(@"bundle://Three20.bundle/images/empty.png");
}

- (NSString*)titleForEmpty {
	return NSLocalizedString(@"No docking stations", nil);
}

- (NSString*)subtitleForEmpty {
	return @"Recently used docking stations will be updated when you login with your Cycle Hire account";
}

@end
