//
//  CycleStreetsPlanner.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 12/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "CycleStreetsPlanner.h"

@implementation CycleStreetsPlanner

// TODO: support for different route types - balanced|fastest|quietest|shortest
static NSString *APItemplate = @"http://www.cyclestreets.net/api/journey.xml?key=%@"\
								"&start_latitude=%f&start_longitude=%f"\
								"&finish_latitude=%f&finish_longitude=%f&segments=0&plan=balanced";

@synthesize APIkey;
@synthesize delegate;

- (id) initWithAPIkey:(NSString *)key delegate:(id<CycleStreetsPlannerDelegate>)_delegate {
	if (self = [super init]) {
		self.APIkey = key;
		self.delegate = _delegate;
	}
	
	return self;
}

- (void) requestDirectionsFrom:(CLLocationCoordinate2D)startCoordinate to:(CLLocationCoordinate2D)finishCoordinate {
	NSString *APIcall = [NSString stringWithFormat:APItemplate, APIkey,
						 startCoordinate.latitude, startCoordinate.longitude,
						 finishCoordinate.latitude, finishCoordinate.longitude];

	NSLog(@"Sending request to %@", APIcall);
	
	if(request != nil) {
		[request cancel];
		[request release];
	}
	
	request = [[TTURLRequest alloc] initWithURL:APIcall delegate:self];
	request.cachePolicy = TTURLRequestCachePolicyNone;
	request.response = [[[TTURLDataResponse alloc] init] autorelease];
	request.httpMethod = @"GET";
	[request send];
}

- (void)requestDidFinishLoad:(TTURLRequest*)_request {
	TTURLDataResponse *response = _request.response;

	if(parser != nil) {
		[parser abortParsing];
		[parser release];
	}
	
	parser = [[TTXMLParser alloc] initWithData:response.data];
	parser.treatDuplicateKeysAsArrayItems = YES;
	parser.delegate = self;
	BOOL parseOK = [parser parse];
	
	if(parseOK) {
		NSDictionary *xmlRoot = parser.rootObject;

		NSString *coordinatesAsString = [[xmlRoot objectForKey:@"marker"]  objectForKey:@"coordinates"];	
	
		NSString *distanceString = [[xmlRoot objectForKey:@"marker"] objectForKey:@"length"];
		NSString *timeString = [[xmlRoot objectForKey:@"marker"] objectForKey:@"time"];
		
		//TODO: detect error message in response
		// <markers><marker type="error" id="1" code="" description="" /></markers>
		
		if (coordinatesAsString == nil) {
			// valid XML but lacks required elements
			[delegate cycleStreetsPlanner:self didFailWithError:
				[NSError errorWithDomain:@"CycleStreetsErrorDomain" code:kCSPErrorInvalidResponse userInfo:nil]];
		}
		
		NSArray *coordinateStrings = [coordinatesAsString componentsSeparatedByCharactersInSet:
									  [NSCharacterSet characterSetWithCharactersInString:@" ,"]];

		NSUInteger numberOfWaypoints = [coordinateStrings count] / 2;
		CLLocationCoordinate2D *waypointArray = 
			(CLLocationCoordinate2D *)malloc(numberOfWaypoints*sizeof(CLLocationCoordinate2D));
		
		for (NSUInteger i=0; i<[coordinateStrings count]; i+=2) {
			CLLocationCoordinate2D coord;
			coord.longitude = [[coordinateStrings objectAtIndex:i] doubleValue];
			coord.latitude = [[coordinateStrings objectAtIndex:i+1] doubleValue];
			waypointArray[i/2] = coord;
		}

		CycleStreetsRoute *result = [[CycleStreetsRoute alloc] initWithWaypointsArray:waypointArray ofSize:numberOfWaypoints];
		result.distanceInMeters = (NSUInteger) [distanceString integerValue];
		result.timeInSeconds = (NSUInteger) [timeString integerValue];
		
		[delegate cycleStreetsPlanner:self didFindRoute:result];
		[result release];
	} else {
		if (parser.parserError.code == NSXMLParserDelegateAbortedParseError) {
			// This isn't an error, we aborted parsing ourselves
			
		}
		[delegate cycleStreetsPlanner:self didFailWithError:parser.parserError];
	}

}

- (void)request:(TTURLRequest*)_request didFailLoadWithError:(NSError*)error {
	[delegate cycleStreetsPlanner:self didFailWithError:error];
}

- (void) cancelPendingRequest {
	if (request != nil && [request isLoading]) {
		[request cancel];
		[request release];
		request = nil;
	}
	
	if (parser != nil) {
		[parser abortParsing];
	}
}

+ (BOOL) shouldUseMilesForDistances {
	NSLocale *locale = [NSLocale currentLocale];
	
	if ([[locale objectForKey:NSLocaleUsesMetricSystem] isEqualToNumber:[NSNumber numberWithBool:FALSE]]) {
		// locale says we're not using metric system
		return YES;
	}
	
	if ([[locale objectForKey:NSLocaleCountryCode] isEqualToString:@"GB"]) {
		// we're in the UK, that uses metric system but still has distances in miles
		// TODO: any other countries behaving in the same way?
		return YES;
	}
	
	return NO;
}

@end
