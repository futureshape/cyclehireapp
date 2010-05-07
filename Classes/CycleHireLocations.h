//
//  CycleHireLocations.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 30/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CycleHireLocation.h"

#define FAVOURITES_FILE	@"favourites.plist"

@interface CycleHireLocations : NSObject {
	NSMutableDictionary *locationsDictionary;
	NSMutableArray *favouriteLocations;
	NSString *favouritesPath;
}

-(id) init;

-(NSArray *)allLocations;
-(NSArray *)favouriteLocations;
-(void)saveFavouriteLocations;
-(CycleHireLocation *)locationWithId: (NSString*) locationId;
@end
