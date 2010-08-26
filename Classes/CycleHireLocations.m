//
//  CycleHireLocations.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 30/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "CycleHireLocations.h"
#import "parseCSV.h"

#import "SynthesizeSingleton.h"

@implementation CycleHireLocations

SYNTHESIZE_SINGLETON_FOR_CLASS(CycleHireLocations);

@synthesize lastUpdatedTimestamp;
@synthesize recentlyUsedDockingStations;

-(id) init {
	if(self = [super init]) {
		
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0]; 
		
		// Load all locations
		
		locationsDictionary = [[NSMutableDictionary alloc] initWithCapacity:400];
		locationsNameDictionary = [[NSMutableDictionary alloc] initWithCapacity:400];
		CSVParser *parser = [CSVParser new];
		
		csvDocPath = [[documentsDirectory stringByAppendingPathComponent:CYCLEHIRE_LOCATIONS_FILE] retain];
		csvTempPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:CYCLEHIRE_LOCATIONS_FILE] retain];
		NSString *csvBundlePath = [[NSBundle mainBundle] pathForResource:@"cyclehire" ofType:@"csv"];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:csvDocPath]) {
			[parser openFile: csvDocPath];
		} else {
			NSLog(@"CycleHireLocations: no list saved in documents, opening from bundle");
			[parser openFile: csvBundlePath];
		}
		
		[parser setDelimiter:','];
		NSMutableArray *hireLocations = [parser parseFile];
		[parser closeFile];
		
		NSString *timeStampString = [[hireLocations objectAtIndex:0] objectAtIndex:0]; 
		NSDate *newTimeStamp = [self timeStampDateFromString:timeStampString];
		self.lastUpdatedTimestamp = newTimeStamp;
		NSLog(@"Loaded initial data with timestamp: %@", lastUpdatedTimestamp);
		[hireLocations removeObjectAtIndex:0]; // Remove first line comment
		
		for (NSArray *hireLocationRecord in hireLocations) {
			CycleHireLocation *location = [[CycleHireLocation alloc] initWithAttributesArray:hireLocationRecord];
			[locationsDictionary setValue:location forKey:location.locationId];
			[locationsNameDictionary setValue:location forKey:location.locationName];
			[location addObserver:self forKeyPath:@"favourite" options:NSKeyValueObservingOptionNew context:nil];
			[location release];
		}
		[parser release];
		NSLog(@"Loaded %d cycle hire locations", [locationsDictionary count]);
		
		// Load favourites
		favouritesPath = [[NSString stringWithFormat:@"%@/%@", documentsDirectory, FAVOURITES_FILE] retain];
		NSArray *favouriteLocationIDs = [NSArray arrayWithContentsOfFile:favouritesPath];
		favouriteLocations = [[NSMutableArray alloc] 
								initWithCapacity:(favouriteLocationIDs == nil ? 1 : [favouriteLocationIDs count])];
		
		if(favouriteLocationIDs != nil) {
			NSLog(@"Loaded %d favourite docking station IDs", [favouriteLocationIDs count]);
			for (NSString *locationID in favouriteLocationIDs) {
				CycleHireLocation *location = [locationsDictionary objectForKey:locationID];
				location.favourite = YES;
			}
		}
		
		// Load recents
		recentsPath = [[documentsDirectory stringByAppendingPathComponent:RECENTS_FILE] retain];
		NSArray *recentDockIds = [NSArray arrayWithContentsOfFile:recentsPath];
		self.recentlyUsedDockingStations = [NSMutableArray arrayWithCapacity:
											(recentDockIds == nil ? 1 : [recentDockIds count])];
		if (recentDockIds != nil) {
			NSLog(@"Loaded %d recently used docking station IDs", [recentDockIds count]);
			for (NSString *locationID in recentDockIds) {
				CycleHireLocation *location = [locationsDictionary objectForKey:locationID];
				[self.recentlyUsedDockingStations addObject:location];
			}
		}
	
		scraper = [[AccountScraper alloc] init];
		scraper.delegate = self;
	}
	return self;
}

-(NSArray *)allLocations {
	return [locationsDictionary allValues];
}

-(CycleHireLocation *)locationWithId: (NSString*) locationId {
	return [locationsDictionary objectForKey:locationId];
}

-(NSMutableArray *)favouriteLocations {
	return favouriteLocations;
}

-(void)saveFavouriteLocations {
	NSMutableArray *locationIds = [[NSMutableArray alloc] initWithCapacity:[favouriteLocations count]];
	for (CycleHireLocation *favLocation in favouriteLocations) {
		[locationIds addObject:favLocation.locationId];
	}
	[locationIds writeToFile:favouritesPath atomically:YES];
	[locationIds release];
	
	NSMutableArray *recentIds = [[NSMutableArray alloc] initWithCapacity:[recentlyUsedDockingStations count]];
	for (CycleHireLocation *recentLocation in recentlyUsedDockingStations) {
		[recentIds addObject:recentLocation.locationId];
	}
	[recentIds writeToFile:recentsPath atomically:YES];
	[recentIds release];
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

- (void) startUpdateFromServer {
	if(updateRequest != nil) {
		[updateRequest cancel];
		[updateRequest release];
	}
	
	updateRequest = [[TTURLRequest alloc] initWithURL:LIVE_DATA_URL delegate:self];
	updateRequest.cachePolicy = TTURLRequestCachePolicyNone;
	updateRequest.response = [[[TTURLDataResponse alloc] init] autorelease];
	updateRequest.httpMethod = @"GET";
	[updateRequest send];
}

- (void)requestDidFinishLoad:(TTURLRequest*)_request {
	TTURLDataResponse *response = _request.response;
	
	NSString *responseString = [[NSString alloc] initWithData:response.data encoding:NSUTF8StringEncoding];
	[responseString writeToFile:csvTempPath atomically:YES encoding:NSUTF8StringEncoding error:NULL];

	CSVParser *parser = [CSVParser new];
	[parser openFile:csvTempPath];
	[parser setDelimiter:','];
	NSMutableArray *hireLocations = [parser parseFile];
	[parser closeFile];
	[parser release];
	
	if ((hireLocations == nil) || [hireLocations count] == 0) {
		NSLog(@"Downloaded invalid data - aborting update");
		return;
	}
	
	NSString *timeStampString = [[hireLocations objectAtIndex:0] objectAtIndex:0]; 
	NSDate *newTimeStamp = [self timeStampDateFromString:timeStampString];
	
	if (newTimeStamp == nil) { 
		NSLog(@"Downloaded invalid data (no timestamp) - aborting update");
		return;
	}
	
	self.lastUpdatedTimestamp = newTimeStamp;
	NSLog(@"Downloaded live data with timestamp: %@", lastUpdatedTimestamp);
	
	[hireLocations removeObjectAtIndex:0]; // Remove timestamp from data (1st line)

	for (NSArray *hireLocationRecord in hireLocations) {
		CycleHireLocation *locationToUpdate = [self locationWithId:[hireLocationRecord objectAtIndex:0]];
		
		if (locationToUpdate == nil) {
			// New location has been added, will be loaded on next app launch
			continue;
		}
		
		NSUInteger newBikes = [(NSString *)[hireLocationRecord objectAtIndex:5] integerValue];
		NSUInteger newSpaces = [(NSString *)[hireLocationRecord objectAtIndex:6] integerValue];
		
		// TEST: by assigning random values below
		locationToUpdate.bikesAvailable = newBikes;
		locationToUpdate.spacesAvailable = newSpaces;
//		locationToUpdate.bikesAvailable = rand() % 10;
//		locationToUpdate.spacesAvailable = rand() % 10;
	}
		
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:csvDocPath error:NULL];
	[fileManager copyItemAtPath:csvTempPath toPath:csvDocPath error:NULL];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:LIVE_DATA_UPDATED_NOTIFICATION object:self];
}

- (void)request:(TTURLRequest*)_request didFailLoadWithError:(NSError*)error {
	if (![self freshDataAvailable]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:LIVE_DATA_TOO_OLD_NOTIFICATION object:self];
	}
}

- (BOOL) freshDataAvailable {
	NSTimeInterval dataAge = -[self.lastUpdatedTimestamp timeIntervalSinceNow];
	
	return !(dataAge > LIVE_DATA_MAX_AGE);
}

- (NSDate *) timeStampDateFromString: (NSString *) timeStampString {
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	[df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	[df setLenient:YES];
	NSDate *timeStamp = [df dateFromString: timeStampString];
	[df release];
	return timeStamp;
}

-(BOOL) updateRecentlyUsedDockingStations {
	if ([[NSUserDefaults standardUserDefaults] objectForKey:kEmailKey] == nil) {
		return NO; // credentials not yet configured, so scraper won't work
	}
	
	[scraper startScraping];
	return YES;
}	

- (void) scraperDidFinishScraping {
	NSDictionary *dockingStationsVisited = scraper.uniqueDockingStationsVisited;
	self.recentlyUsedDockingStations = [NSMutableArray arrayWithCapacity:[dockingStationsVisited count]];
	
	for (NSString *fullName in [dockingStationsVisited allKeys]) {
		NSString *halfName = [[fullName componentsSeparatedByString:@","] objectAtIndex:0];
		CycleHireLocation *matchingLocation =
			[locationsNameDictionary objectForKey:[halfName stringByTrimmingCharactersInSet:
												   [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		
		matchingLocation.lastUsed = [dockingStationsVisited objectForKey:fullName];
		[recentlyUsedDockingStations addObject:matchingLocation];
	}
	
	[recentlyUsedDockingStations sortUsingSelector:@selector(compareLastUsed:)];
	[[NSNotificationCenter defaultCenter] postNotificationName:RECENTS_UPDATED_NOTIFICATION object:self];
}

- (void) scraperDidFailWithError:(NSError *)error {
	// We don't care :)
}

- (void) dealloc {
	[super dealloc];
	[favouriteLocations release];
	[locationsDictionary release];
	[locationsNameDictionary release];
	[favouritesPath release];
	[recentlyUsedDockingStations release];
	[recentsPath release];
	[csvDocPath release];
	[scraper release];
}

@end
