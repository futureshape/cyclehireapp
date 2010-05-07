//
//  PostcodeDatabase.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 04/05/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "PostcodeDatabase.h"

@implementation PostcodeDatabase

- (id)initWithDatabasePath:(NSString *)dbPath {
	if (self = [super init]) {
		postcodes = [[FMDatabase alloc] initWithPath:dbPath];
		if (![postcodes open]) {
			[self release];
			return nil;
		}
	}
	return self;
}

- (CLLocationCoordinate2D) coordinateForPostcode: (NSString *)postcode {
	CLLocationCoordinate2D coordinate = CLInvalidCoordinate();
	FMResultSet* rs = [postcodes executeQuery:@"SELECT lat,long FROM postcodes WHERE postcode=?", postcode];
	if ([rs next]) {
		coordinate.latitude = [rs doubleForColumn:@"lat"];
		coordinate.longitude = [rs doubleForColumn:@"long"];
	} 
	[rs close];
	return coordinate;
}

+ (BOOL) isValidPostcode: (NSString *)postcode {
	NSString *postcodeRegex = @"(GIR 0AA|[A-PR-UWYZ]([0-9]{1,2}|([A-HK-Y][0-9]|[A-HK-Y][0-9]([0-9]|[ABEHMNPRV-Y]))|[0-9][A-HJKPS-UW])[0-9][ABD-HJLNP-UW-Z]{2})";
	
	NSRange postcodeRange = [postcode rangeOfRegex:postcodeRegex];
	return (postcodeRange.location == 0) && (postcodeRange.length == [postcode length]);
}

- (void) validateDatabase {
	// for testing only
	
	FMResultSet* rs = [postcodes executeQuery:@"SELECT postcode FROM postcodes"];
	while ([rs next]) {
		NSString *testPostcode = [rs stringForColumn:@"postcode"];
		NSAssert1([PostcodeDatabase isValidPostcode:testPostcode], @"Postcode %@ didn't validate", testPostcode);
	} 
	[rs close];
}

- (void) dealloc {
	[super dealloc];
	[postcodes release]; // will also close the db
}

@end
