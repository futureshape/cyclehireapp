//
//  CycleStreetsPlanner.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 12/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Three20/Three20.h>

#import "CycleStreetsRoute.h"

@class CycleStreetsPlanner;

@protocol CycleStreetsPlannerDelegate

- (void) cycleStreetsPlanner: (CycleStreetsPlanner *)planner didFindRoute: (CycleStreetsRoute *) route;
- (void) cycleStreetsPlanner: (CycleStreetsPlanner *)planner didFailWithError:(NSError *)error;

@end

@interface CycleStreetsPlanner : NSObject <TTURLRequestDelegate> {
	NSString *APIkey;
	id<CycleStreetsPlannerDelegate> delegate;
	
	TTURLRequest *request;
	TTXMLParser *parser;
}

@property (nonatomic, retain) NSString *APIkey;
@property (nonatomic, retain) NSString *delegate;

- (id) initWithAPIkey:(NSString *)key delegate:(id<CycleStreetsPlannerDelegate>)_delegate;

- (void) requestDirectionsFrom:(CLLocationCoordinate2D)startCoordinate to:(CLLocationCoordinate2D)finishCoordinate;

- (void) cancelPendingRequest;

+ (BOOL) shouldUseMilesForDistances;

@end

typedef enum {
	kCSPErrorInvalidResponse = 0 // Can't find the required elements in the XML response from CycleStreets 
} CSPError;

