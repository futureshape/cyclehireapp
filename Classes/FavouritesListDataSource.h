//
//  FavouritesListDataSource.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 28/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"

#import "CycleHireLocations.h";

@interface FavouritesListDataSource : TTListDataSource {
	NSArray *favouriteLocations;
}

- (id)initWithFavouriteLocations: (NSArray *) favouriteLocations;
-(TTTableItem*) tableItemForLocation:(CycleHireLocation*)location;

@end
