//
//  CycleHireLocation.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 09/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CycleHireLocation : NSObject {
	NSString *locationId;
	NSString *locationName;
	NSString *postcodeArea;
	CLLocationCoordinate2D coordinate;
	NSUInteger capacity;
	BOOL favourite;
	
	// Dummy variables below at the moment:
	NSUInteger bikesAvailable;
	NSUInteger spacesAvailable;
}

@property(nonatomic, retain) NSString *locationId;
@property(nonatomic, retain) NSString *locationName;
@property(nonatomic, retain) NSString *postcodeArea;
@property(nonatomic) CLLocationCoordinate2D coordinate;
@property(nonatomic) NSUInteger capacity;
@property(nonatomic) BOOL favourite;

- (id) initWithLocationId: (NSString *)_locationId 
					 name:(NSString *)_locationName 
				 postcode:(NSString *)_postcodeArea 
				 location:(CLLocationCoordinate2D)_coordinate 
				 capacity: (NSUInteger) _capacity;
- (id) initWithAttributesArray:(NSArray *)array;

- (NSString *)localizedBikesAvailableText;
- (NSString *)localizedSpacesAvailableText;
@end
