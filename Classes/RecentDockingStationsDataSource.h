//
//  RecentDockingStationsDataSource.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 23/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Three20/Three20.h"

#import "CycleHireLocations.h"
#import "AccountScraper.h"

@interface RecentDockingStationsDataSource : TTListDataSource {
	BOOL updating;
}

@property (nonatomic) BOOL updating;

- (id)init;
-(TTTableItem*) tableItemForLocation:(CycleHireLocation*)location;
-(void) refreshData;

@end
