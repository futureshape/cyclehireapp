//
//  CycleHireLocations.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 30/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "CycleHireLocations.h"
#import "parseCSV.h"

@implementation CycleHireLocations

-(id) init {
	if(self = [super init]) {
		
		// Load all locations
		
		locationsDictionary = [[NSMutableDictionary alloc] init];
		
		CSVParser *parser = [CSVParser new];
		NSString *csvPath = [[NSBundle mainBundle] pathForResource:@"cyclehire" ofType:@"csv"]; 
		[parser openFile: csvPath];
		NSArray *hireLocations = [parser parseFile];
		[parser closeFile];
		
		for (NSArray *hireLocationRecord in hireLocations) {
			CycleHireLocation *location = [[CycleHireLocation alloc] initWithAttributesArray:hireLocationRecord];
			[locationsDictionary setValue:location forKey:location.locationId];
			[location addObserver:self forKeyPath:@"favourite" options:NSKeyValueObservingOptionNew context:nil];
			[location release];
		}
		[parser release];
		NSLog(@"Loaded %d cycle hire locations", [locationsDictionary count]);
		
		// Load favourites
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0]; 
		favouritesPath = [[NSString stringWithFormat:@"%@/%@", documentsDirectory, FAVOURITES_FILE] retain];
		
		NSArray *favouriteLocationIDs = [NSMutableArray arrayWithContentsOfFile:favouritesPath];
	
		favouriteLocations = [[NSMutableArray alloc] 
								initWithCapacity:(favouriteLocationIDs == nil ? 1 : [favouriteLocationIDs count])];
		
		if(favouriteLocationIDs != nil) {
			NSLog(@"Loaded %d favourite cycle hire location IDs", [favouriteLocationIDs count]);
			for (NSString *locationID in favouriteLocationIDs) {
				CycleHireLocation *location = [locationsDictionary objectForKey:locationID];
				location.favourite = YES;
			}
		}
	}
	return self;
}

-(NSArray *)allLocations {
	return [locationsDictionary allValues];
}

-(CycleHireLocation *)locationWithId: (NSString*) locationId {
	return [locationsDictionary objectForKey:locationId];
}

-(NSArray *)favouriteLocations {
	return favouriteLocations;
}

-(void)saveFavouriteLocations {
	NSMutableArray *locationIds = [[NSMutableArray alloc] initWithCapacity:[favouriteLocations count]];
	for (CycleHireLocation *favLocation in favouriteLocations) {
		[locationIds addObject:favLocation.locationId];
	}
	[locationIds writeToFile:favouritesPath atomically:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	CycleHireLocation *modifiedCycleHireLocation = (CycleHireLocation *)object;
	
	if (modifiedCycleHireLocation.favourite == YES) {
		// location was added to favourites
		NSLog(@"Added to favourites: %@", [modifiedCycleHireLocation description]);
		[favouriteLocations addObject:modifiedCycleHireLocation];
	} else {
		// location was removed from favourites
		NSLog(@"Removed from favourites: %@", [modifiedCycleHireLocation description]);
		[favouriteLocations removeObject:modifiedCycleHireLocation];
	}
}

- (void) dealloc {
	[super dealloc];
	[favouriteLocations release];
	[locationsDictionary release];
	[favouritesPath release];
}

@end
