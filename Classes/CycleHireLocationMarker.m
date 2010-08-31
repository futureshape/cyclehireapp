//
//  CycleHireLocationMarker.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 29/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#define ANCHOR_POINT CGPointMake(0.3, 1.0)

#import "CycleHireLocationMarker.h"

@implementation CycleHireLocationMarker

- (id) initWithLocation: (CycleHireLocation *) _location {
	location = [_location retain];
	
	self = [super initWithUIImage:[self markerImage] anchorPoint:ANCHOR_POINT]; 
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(updateMarkerImage) 
												 name:LIVE_DATA_UPDATED_NOTIFICATION 
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(updateMarkerImage) 
												 name:LIVE_DATA_TOO_OLD_NOTIFICATION 
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(zoomedIn) 
												 name:ZOOMING_IN_NOTIFICATION 
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(zoomedOut) 
												 name:ZOOMING_OUT_NOTIFICATION 
											   object:nil];
	return self;
}

- (void) updateMarkerImage {
	[self replaceUIImage:[self markerImage] anchorPoint:ANCHOR_POINT];
}

- (void) zoomedIn {
	zoomedIn = YES;
	[self updateMarkerImage];
}

- (void) zoomedOut {
	zoomedIn = NO;
	[self updateMarkerImage];
}

- (UIImage *) markerImage {
	
	if (!zoomedIn) {
		return [UIImage imageNamed:@"x-marker-small.png"];
	}
	
	if (![[CycleHireLocations sharedCycleHireLocations] freshDataAvailable]) {
		return [UIImage imageNamed:@"x-marker.png"];
	}
	
	if (location.capacity == 0) {
		return [UIImage imageNamed:@"0-marker.png"];
	}
	
	double percentage = (double) location.bikesAvailable / location.capacity;
	
	if (percentage == 0.0) {
		return [UIImage imageNamed:@"0-marker.png"];
	} else if (percentage == 1.0) {
		return [UIImage imageNamed:@"8-marker.png"];
	} else {
		NSUInteger markerCode = (NSUInteger) round(percentage * 8);
		if (markerCode == 0) markerCode++; // some bikes available, but rounded down to 0
		if (markerCode == 8) markerCode--; // some spaces available, but rounded up to 8
		return [UIImage imageNamed:[NSString stringWithFormat:@"%d-marker.png", markerCode]];
	}
}

- (void) dealloc {
	[super dealloc];
	[location release];
}

@end
