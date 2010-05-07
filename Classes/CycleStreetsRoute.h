//
//  CycleStreetsRoute.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 13/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CycleStreetsRoute : NSObject {
	CLLocationCoordinate2D *waypointsArray;
	NSUInteger numberOfWaypoints;
	NSUInteger distanceInMeters;
	NSUInteger timeInSeconds;
}

@property (nonatomic, readonly) NSUInteger numberOfWaypoints;

@property (nonatomic, readwrite) NSUInteger distanceInMeters;
@property (nonatomic, readwrite) NSUInteger timeInSeconds;

// ownership of array passes to CycleStreesRoute object, which will free the array upon dealloc
-(id) initWithWaypointsArray:(CLLocationCoordinate2D*)array ofSize:(NSUInteger) size;

-(CLLocationCoordinate2D) waypointAtIndex: (NSUInteger) index;

@end
