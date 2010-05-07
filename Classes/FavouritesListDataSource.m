//
//  FavouritesListDataSource.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 28/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "FavouritesListDataSource.h"

@implementation FavouritesListDataSource

- (id)initWithFavouriteLocations: (NSArray *) _favouriteLocations {
	favouriteLocations = _favouriteLocations;
	if (self = [super init]) {
		for (CycleHireLocation *location in favouriteLocations) {
			[self.items addObject:[self tableItemForLocation:location]];
		}
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

-(TTTableItem*) tableItemForLocation:(CycleHireLocation*)location {
	NSString *title = [NSString stringWithFormat:@"%@, %@", location.locationName, location.postcodeArea];
	NSString *subtitle = [NSString stringWithFormat:@"%@, %@", 
						  [location localizedBikesAvailableText], 
						  [location localizedSpacesAvailableText]];
	
	// Need to replaces slashes in TfL reference with the url-encoded alternative
	NSString *encodedLocationId = [location.locationId stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	NSString *URL = [NSString stringWithFormat:@"cyclehire://map/cycleHireLocation/%@", encodedLocationId];
	return [TTTableSubtitleItem itemWithText:title subtitle:subtitle URL:URL];
}

@end
