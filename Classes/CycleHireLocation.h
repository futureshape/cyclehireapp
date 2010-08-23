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
	NSString *villageName;
	CLLocationCoordinate2D coordinate;
	BOOL favourite;
	
	NSUInteger bikesAvailable;
	NSUInteger spacesAvailable;
	
	NSDate *lastUsed;
}

@property(nonatomic, retain) NSString *locationId;
@property(nonatomic, retain) NSString *locationName;
@property(nonatomic, retain) NSString *villageName;
@property(nonatomic) CLLocationCoordinate2D coordinate;
@property(nonatomic) NSUInteger bikesAvailable;
@property(nonatomic) NSUInteger spacesAvailable;
@property(nonatomic,readonly) NSUInteger capacity;
@property(nonatomic) BOOL favourite;
@property(nonatomic, retain) NSDate *lastUsed;

- (id) initWithLocationId: (NSString *)_locationId 
					 name: (NSString *)_locationName 
				  village: (NSString *)_villageName 
				 location: (CLLocationCoordinate2D)_coordinate 
		   bikesAvailable: (NSUInteger) _bikes
		  spacesAvailable: (NSUInteger) _spaces;
- (id) initWithAttributesArray:(NSArray *)array;

- (NSString *)localizedBikesAvailableText;
- (NSString *)localizedSpacesAvailableText;
- (NSString *)localizedCapacityText;
- (NSUInteger) capacity;
- (NSComparisonResult) compareLastUsed: (CycleHireLocation *)otherLocation; 
@end
