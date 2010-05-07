//
//  CycleStreetsRoute.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 13/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "CycleStreetsRoute.h"

@implementation CycleStreetsRoute

@synthesize numberOfWaypoints;
@synthesize distanceInMeters;
@synthesize timeInSeconds;

-(id) initWithWaypointsArray:(CLLocationCoordinate2D*)array ofSize:(NSUInteger) size {
	if(self = [super init]) {
		waypointsArray = array;
		numberOfWaypoints = size;
	}

	return self;
}

-(CLLocationCoordinate2D) waypointAtIndex: (NSUInteger) index {
	NSAssert((index >= 0) && (index < numberOfWaypoints), @"index out of bounds");
	return waypointsArray[index];
}
 
-(void) dealloc {
	[super dealloc];
	free(waypointsArray);
}

@end
