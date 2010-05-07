//
//  PostcodeDatabase.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 04/05/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreLocation/CoreLocation.h>
#import "CoreLocationAdditions.h"

#import "RegexKitLite.h"

#import "FMDatabase.h"

@interface PostcodeDatabase : NSObject {
	FMDatabase *postcodes;
}

- (id)initWithDatabasePath:(NSString *)dbPath;

- (CLLocationCoordinate2D) coordinateForPostcode: (NSString *)postcode;

+ (BOOL) isValidPostcode: (NSString *)postcode;

@end
