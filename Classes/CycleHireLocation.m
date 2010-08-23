//
//  CycleHireLocation.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 09/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "CycleHireLocation.h"

@implementation CycleHireLocation

@synthesize locationId;
@synthesize locationName;
@synthesize villageName;
@synthesize coordinate;
@synthesize bikesAvailable;
@synthesize spacesAvailable;
@synthesize favourite;
@synthesize lastUsed;

- (id) initWithLocationId: (NSString *)_locationId 
					 name: (NSString *)_locationName 
				  village: (NSString *)_villageName 
				 location: (CLLocationCoordinate2D)_coordinate 
		   bikesAvailable: (NSUInteger) _bikes
		  spacesAvailable: (NSUInteger) _spaces {
	
	if (self = [super init]) {
		self.locationId = _locationId;
		self.locationName = _locationName;
		self.villageName = _villageName;
		self.coordinate = _coordinate;
		self.spacesAvailable = _spaces;
		self.bikesAvailable = _bikes;
		self.lastUsed = [NSDate distantPast];
	}
	
	return self;
}

- (id) initWithAttributesArray:(NSArray *)array {
	NSString *_locationId = (NSString *)[array objectAtIndex:0];
	NSString *_locationName = (NSString *)[array objectAtIndex:1];
	NSString *_villageName = (NSString *)[array objectAtIndex:2];
	
	CLLocationCoordinate2D _coordinate;
	_coordinate.latitude = [(NSString *)[array objectAtIndex:3] doubleValue];
	_coordinate.longitude = [(NSString *)[array objectAtIndex:4] doubleValue];
	
	NSUInteger _bikes = [(NSString *)[array objectAtIndex:5] integerValue];
	NSUInteger _spaces = [(NSString *)[array objectAtIndex:6] integerValue];
		
	return [self initWithLocationId:_locationId
							   name:_locationName 
							village:_villageName 
						   location:_coordinate 
					 bikesAvailable:_bikes
					spacesAvailable:_spaces];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"CycleHireLocation: %@, %@ [%@] (%f,%f) b:%d s:%d c:%d", 
			self.locationName, self.villageName, self.locationId, 
			self.coordinate.latitude, self.coordinate.longitude, self.bikesAvailable, self.spacesAvailable, self.capacity];
}

- (NSString *)localizedBikesAvailableText {
	if (bikesAvailable == 0) {
		return NSLocalizedString(@"No bikes available", nil);
	} else if (bikesAvailable == 1) {
		return NSLocalizedString(@"1 bike available", nil);
	} else {
		return [NSString stringWithFormat:NSLocalizedString(@"%d bikes available", nil), bikesAvailable];
	}
}

- (NSString *)localizedSpacesAvailableText {
	if (spacesAvailable == 0) {
		return NSLocalizedString(@"No free spaces", nil);
	} else if (spacesAvailable == 1) {
		return NSLocalizedString(@"1 free space", nil);
	} else {
		return [NSString stringWithFormat:NSLocalizedString(@"%d free spaces", nil), spacesAvailable];
	}
}

- (NSString *)localizedCapacityText {
	if (self.capacity == 0) {
		return NSLocalizedString(@"Out of order", nil);
	} else if (self.capacity == 1) {
		return NSLocalizedString(@"1 docking point", nil);
	} else {
		return [NSString stringWithFormat:NSLocalizedString(@"%d docking points", nil), self.capacity];
	}
}


- (NSUInteger) capacity {
	return self.spacesAvailable + self.bikesAvailable;
}

- (NSComparisonResult) compareLastUsed: (CycleHireLocation *)otherLocation {
	// reverse sort order - we want newest on top
	return -[self.lastUsed compare:otherLocation.lastUsed];
}

@end
