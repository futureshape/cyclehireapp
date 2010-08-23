//
//  FavouritesListDataSource.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 28/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "FavouritesListDataSource.h"

@implementation FavouritesListDataSource

- (id)initWithCycleHireLocations: (CycleHireLocations *) _cycleHireLocations {
	cycleHireLocations = _cycleHireLocations;
	favouriteLocations = [cycleHireLocations favouriteLocations];
	if (self = [super init]) {
		self.sections = [NSArray arrayWithObjects:@"Marked as favourites", @"Recently used", nil];
		[self refreshData];
	}
	return self;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.items removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
		
		CycleHireLocation *deletedLocation = [favouriteLocations objectAtIndex:indexPath.row];
		deletedLocation.favourite = NO;
    }   
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	NSUInteger fromRow = fromIndexPath.row;
	NSUInteger toRow = toIndexPath.row;
	
	[favouriteLocations moveRowAtIndex:fromRow toIndex:toRow];
	
	NSLog(@"favs after move: %@", favouriteLocations);
	
	[self refreshData];
}

-(void) refreshData {
	NSMutableArray *favouritesTableItems = [NSMutableArray arrayWithCapacity:[favouriteLocations count]];
	for (CycleHireLocation *location in favouriteLocations) {
		[favouritesTableItems addObject:[self tableItemForLocation:location]];
	}	

	NSMutableArray *recentlyUsedTableItems = [NSMutableArray arrayWithCapacity:10];
	[recentlyUsedTableItems addObject:[TTTableLongTextItem itemWithText:
									   @"Recently used docking stations will appear here after you login to your Cycle Hire account"]];

	self.items = [NSArray arrayWithObjects:favouritesTableItems, recentlyUsedTableItems, nil];
}

-(TTTableItem*) tableItemForLocation:(CycleHireLocation*)location {
	NSString *title = [NSString stringWithFormat:@"%@, %@", location.locationName, location.villageName];
	
	NSString *subtitle;
	if ([cycleHireLocations freshDataAvailable]) {
		subtitle = [NSString stringWithFormat:@"%@, %@", 
					[location localizedBikesAvailableText], 
					[location localizedSpacesAvailableText]];
	} else {
		subtitle = [location localizedCapacityText];
	}
	
	// Need to replace slashes in TfL reference with the url-encoded alternative
	NSString *encodedLocationId = [location.locationId stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	NSString *URL = [NSString stringWithFormat:@"cyclehire://map/cycleHireLocation/%@", encodedLocationId];
	return [TTTableSubtitleItem itemWithText:title subtitle:subtitle URL:URL];
}

- (UIImage*)imageForEmpty {
	return TTIMAGE(@"bundle://Three20.bundle/images/empty.png");
}

- (NSString*)titleForEmpty {
	return NSLocalizedString(@"No favourites", nil);
}

- (NSString*)subtitleForEmpty {
	return NSLocalizedString(@"To add a cycle hire location to your favourites, "\
							 "tap on the location marker on the map and select 'Add to favourites'", nil);
}

@end
