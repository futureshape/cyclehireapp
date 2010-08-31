//
//  CycleHireLocationMarker.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 29/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMMarker.h"
#import	"CycleHireLocation.h"
#import "CycleHireLocations.h"

#define ZOOMING_IN_NOTIFICATION @"CHLMZoomingIn"
#define ZOOMING_OUT_NOTIFICATION @"CHLMZoomingOut"

@interface CycleHireLocationMarker : RMMarker {
	CycleHireLocation *location;
	BOOL zoomedIn;
}

- (id) initWithLocation: (CycleHireLocation *)location;
- (UIImage *) markerImage;

@end
