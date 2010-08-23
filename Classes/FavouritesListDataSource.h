//
//  FavouritesListDataSource.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 28/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"

#import "CycleHireLocations.h"

#import "NSMutableArray-RowMoving.h"

@interface FavouritesListDataSource : TTListDataSource {
	CycleHireLocations *cycleHireLocations;
	NSMutableArray *favouriteLocations;
}

- (id)initWithCycleHireLocations: (CycleHireLocations *) cycleHireLocations;
-(TTTableItem*) tableItemForLocation:(CycleHireLocation*)location;
-(void) refreshData;

@end
