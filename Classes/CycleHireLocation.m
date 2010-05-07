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
@synthesize postcodeArea;
@synthesize coordinate;
@synthesize capacity;
@synthesize favourite;

- (id) initWithLocationId: (NSString *)_locationId 
					 name:(NSString *)_locationName 
				 postcode:(NSString *)_postcodeArea 
				 location:(CLLocationCoordinate2D)_coordinate 
				 capacity: (NSUInteger) _capacity {
	
	if (self = [super init]) {
		self.locationId = _locationId;
		self.locationName = _locationName;
		self.postcodeArea = _postcodeArea;
		self.coordinate = _coordinate;
		self.capacity = _capacity;
		
		spacesAvailable = self.capacity;
		bikesAvailable = 0;
	}
	
	return self;
}

- (id) initWithAttributesArray:(NSArray *)array {
	NSString *_locationId = (NSString *)[array objectAtIndex:0];
	NSString *_locationName = (NSString *)[array objectAtIndex:1];
	NSString *_postcodeArea = (NSString *)[array objectAtIndex:2];
	
	CLLocationCoordinate2D _coordinate;
	_coordinate.latitude = [(NSString *)[array objectAtIndex:3] doubleValue];
	_coordinate.longitude = [(NSString *)[array objectAtIndex:4] doubleValue];
	
	NSUInteger _capacity = [(NSString *)[array objectAtIndex:5] integerValue];
	
	return [self initWithLocationId:_locationId
							   name:_locationName 
						   postcode:_postcodeArea 
						   location:_coordinate 
						   capacity:_capacity];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"CycleHireLocation: %@, %@ [%@] (%f,%f) c:%d", 
			self.locationName, self.postcodeArea, self.locationId, 
			self.coordinate.latitude, self.coordinate.longitude, self.capacity];
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


@end
