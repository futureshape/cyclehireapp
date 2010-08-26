//
//  CycleHireLocations.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 30/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "CycleHireLocation.h"
#import "AccountScraper.h"

// Files
#define FAVOURITES_FILE	@"favourites.plist"
#define RECENTS_FILE @"recents.plist"
#define	CYCLEHIRE_LOCATIONS_FILE @"cyclehire.csv"

// Feeds
#define LIVE_DATA_URL @"http://cyclehireapp.com/cyclehirelive/cyclehire.csv"

// Notifications
#define	LIVE_DATA_UPDATED_NOTIFICATION @"LiveDataUpdated"
#define	LIVE_DATA_TOO_OLD_NOTIFICATION @"LiveDataTooOld"
#define RECENTS_UPDATED_NOTIFICATION @"RecentsUpdated"

// Time constants
#define	LIVE_DATA_MAX_AGE (10*60) // 10 minutes 

@interface CycleHireLocations : NSObject <AccountScraperDelegate> {
	NSMutableDictionary *locationsDictionary;
	NSMutableDictionary *locationsNameDictionary;
	NSMutableArray *favouriteLocations;
	
	NSString *favouritesPath;
	NSString *recentsPath;
	NSString *csvDocPath;
	NSString *csvTempPath;
	
	TTURLRequest *updateRequest;
	
	NSDate *lastUpdatedTimestamp;
	
	AccountScraper *scraper;
	
	NSMutableArray *recentlyUsedDockingStations;
}

@property(nonatomic, retain) NSDate *lastUpdatedTimestamp;
@property(nonatomic, retain) NSMutableArray *recentlyUsedDockingStations;

-(id) init;

-(NSArray *)allLocations;
-(NSMutableArray *)favouriteLocations;
-(void)saveFavouriteLocations;
-(CycleHireLocation *)locationWithId: (NSString*) locationId;
- (void) startUpdateFromServer;
- (BOOL) freshDataAvailable;
- (NSDate *) timeStampDateFromString: (NSString *) timeStampString;
-(BOOL) updateRecentlyUsedDockingStations;
@end
