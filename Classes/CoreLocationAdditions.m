/*
 *  CoreLocationAdditions.m
 *  CycleHire
 *
 *  Created by Alexander Baxevanis on 15/04/2010.
 *  Copyright 2010 Alexander Baxevanis. All rights reserved.
 *
 */

#import "CoreLocationAdditions.h"

CLLocationCoordinate2D CLInvalidCoordinate() {
	CLLocationCoordinate2D _invalid = {.latitude = MAXFLOAT, .longitude = MAXFLOAT };
	return _invalid;
}

BOOL CLIsValidCoordinate(CLLocationCoordinate2D coordinate) {
	return (coordinate.latitude != MAXFLOAT) && (coordinate.longitude != MAXFLOAT);
}
