//
//  MapViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 17/03/2010.
//  Copyright Alexander Baxevanis 2010. All rights reserved.
//

#import "MapViewController.h"

#define kAccuracyCircleStrokeWidth 4.0 // pixels

#define kDefaultStartLocationLat	51.507247 // Centre of London
#define kDefaultStartLocationLong	-0.128746
#define kDefaultStartZoom			14

#define kLocationTooOld	(5 * 60) // 5 minutes

#define kAnimationOpenPopup @"kAOP"
#define kAnimationClosePopup @"kACP"

#define CYCLESTREETS_API_KEY @"77e632deb63b5fbc"

@implementation MapViewController

@synthesize mapView;
@synthesize drawerView;

@synthesize locationCrosshairButton;
@synthesize locationSearchActivity;

@synthesize directionsOverlayView;
@synthesize directionsActivity;
@synthesize directionsLabel;

@synthesize stationsViewController;
@synthesize currentlyVisibleMarker;

- (id)init {
	return [super initWithNibName:@"RootViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    [mapView setDelegate:self];
	
	CLLocationCoordinate2D startLocation;
	float startZoom;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if([defaults objectForKey:kLastLocationLatKey] == nil) {
		startLocation.latitude	= kDefaultStartLocationLat;
		startLocation.longitude = kDefaultStartLocationLong;
		startZoom = kDefaultStartZoom;
	} else {
		NSLog(@"Loading saved coordinates");
		startLocation.latitude	= [defaults doubleForKey:kLastLocationLatKey];
		startLocation.longitude = [defaults doubleForKey:kLastLocationLongKey];
		startZoom = [defaults floatForKey:kLastLocationZoomKey];
	}
		
	RMDBMapSource* dbTilesource = [[[RMDBMapSource alloc]  
									initWithPath:@"LDNZone1.db"] autorelease];
	
	coverageTopLeft = [dbTilesource topLeftOfCoverage];
	coverageBottomRight = [dbTilesource bottomRightOfCoverage];
	
	[[[RMMapContents alloc] initWithView:mapView 
							  tilesource:dbTilesource
							centerLatLon:startLocation 
							   zoomLevel:startZoom
							maxZoomLevel:16
							minZoomLevel:13 
						 backgroundImage:nil] autorelease];
	[self loadCycleHireLocations];
	
	drawerViewVisible = NO;
	locationManager = nil;
	locationState = kLocationCancelled;
	
	directionsStartingPoint = CLInvalidCoordinate();
	directionsFinishPoint = CLInvalidCoordinate();
	
	postcodes = [[PostcodeDatabase alloc] initWithDatabasePath:[[NSBundle mainBundle] pathForResource:@"postcodes" ofType:@"db"]];
	
	NSLog(@"Miles = %d", [CycleStreetsPlanner shouldUseMilesForDistances]);
	
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = YES;
	self.navigationItem.title = NSLocalizedString(@"Map", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; 
	self.stationsViewController = nil;
}

- (void) loadCycleHireLocations {
	
	cycleHireLocations = [[CycleHireLocations alloc] init];
	markersForLocations = [[NSMutableDictionary alloc] initWithCapacity:[[cycleHireLocations allLocations] count]];
	
	for (CycleHireLocation *location in [cycleHireLocations allLocations]) {
		UIImage *bikeMarkerImage = [UIImage imageNamed:(mapView.contents.zoom < 14.5 ? @"marker-blue-bike-small.png" : @"marker-blue-bike.png")]; 
		RMMarker *locationMarker = [[RMMarker alloc] initWithUIImage:bikeMarkerImage anchorPoint:CGPointMake(0.5, 1.0)];
		locationMarker.data = location;
		[[mapView markerManager] addMarker:locationMarker AtLatLong:location.coordinate];
		[markersForLocations setObject:locationMarker forKey:location.locationId];
		[locationMarker release];
	}
}

- (void)dealloc {
    self.mapView = nil; 
	self.stationsViewController = nil;
	[planner release];
	[postcodes release];
    [super dealloc]; 
}

#pragma mark -
#pragma mark Map delegate methods

- (void) afterMapMove: (RMMapView*) map {
	
	// NOTE: this only gets called when map is moved by touch, not programmatically
	if (locationState == kLocationTracking) {
		[self setLocationState:kLocationVisible];
	}
	
	// Stops the map view from being dragged outside the area covered by the preloaded map
	
	CLLocationCoordinate2D viewTopLeft = [map.contents pixelToLatLong:CGPointZero];
	CLLocationCoordinate2D viewBottomRight = [map.contents pixelToLatLong:CGPointMake(map.bounds.size.width, map.bounds.size.height)];
	CLLocationCoordinate2D mapCenter = [map.contents mapCenter]; 
	
	if (viewTopLeft.latitude > coverageTopLeft.latitude) {				// Latitude out of topLeft 
		mapCenter.latitude -= viewTopLeft.latitude - coverageTopLeft.latitude; 
	}
	
	if (viewTopLeft.longitude < coverageTopLeft.longitude) {			// Longitude out of topLeft
		mapCenter.longitude -= viewTopLeft.longitude - coverageTopLeft.longitude; 
	}

	if (viewBottomRight.latitude < coverageBottomRight.latitude) {		// Latitude out of bottomRight
		mapCenter.latitude -= viewBottomRight.latitude - coverageBottomRight.latitude; 
	}
	
	if (viewBottomRight.longitude > coverageBottomRight.longitude) {	// Longitude out of bottomRight 
		mapCenter.longitude -= viewBottomRight.longitude - coverageBottomRight.longitude; 
	}	
	
	[map.contents moveToLatLong:mapCenter];
}

- (void) afterMapZoom: (RMMapView*) map byFactor: (float) zoomFactor near:(CGPoint) center {

	// NOTE: when the map gets zoomed programmatically, we call this with zoomFactor = 0, center = 0
	if (locationState == kLocationTracking && !CGPointEqualToPoint(center, CGPointZero)) {
		[self setLocationState:kLocationVisible];
	}
	
	if(accuracyCircleMarker != nil) {
		UIImage *circleImage = [self makeAccuracyMarkerImage];
		[accuracyCircleMarker replaceUIImage:circleImage];
	}
	
	if (map.contents.zoom < 14.5) {
		for (CALayer *marker in [[map markerManager] markers]) {
			if (![marker isMemberOfClass:[RMMarker class]]) continue;
			if (![((RMMarker*)marker).data isMemberOfClass:[CycleHireLocation class]]) continue;
			if (marker.bounds.size.width == [UIImage imageNamed:@"marker-blue-bike-small.png"].size.width) break;
			[(RMMarker*)marker replaceUIImage:[UIImage imageNamed:@"marker-blue-bike-small.png"] anchorPoint:CGPointMake(0.5, 1.0)];
		} 
		
	} else {
		for (RMMarker *marker in [[map markerManager] markers]) {
			if (![marker isMemberOfClass:[RMMarker class]]) continue;
			if (![((RMMarker*)marker).data isMemberOfClass:[CycleHireLocation class]]) continue;
			if (marker.bounds.size.width == [UIImage imageNamed:@"marker-blue-bike.png"].size.width) break;
			[(RMMarker*)marker replaceUIImage:[UIImage imageNamed:@"marker-blue-bike.png"] anchorPoint:CGPointMake(0.5, 1.0)];
		} 
	}

}

- (void) singleTapOnMap: (RMMapView*) map At: (CGPoint) point {
	if (drawerViewVisible && !CGRectContainsPoint(self.drawerView.frame, point)) {
		[self toggleDrawerView];
	}
}

#pragma mark -
#pragma mark Location popup view 

- (void) tapOnMarker: (RMMarker*) marker onMap: (RMMapView*) map {
	// only handle clicks for cycle hire location markers
	if(![marker.data isMemberOfClass:[CycleHireLocation class]]) return; 
	
	if (drawerViewVisible) {
		[self toggleDrawerView];
	}
	
	if(popupView == nil) {
		[self makeLocationPopup];
	}
		
	self.currentlyVisibleMarker = marker;

	CGRect fullFrame = CGRectMake(12, 35, 304, 380);
	CGRect initialFrame = CGRectMake(marker.position.x, marker.position.y, 0, 0);
	
	popupView.frame = initialFrame;
	[mapView addSubview:popupView];
	
	[locationPopupViewController updateForLocation:(CycleHireLocation *)marker.data];
	
	[UIView beginAnimations:kAnimationOpenPopup context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	popupView.frame = fullFrame;
	[UIView commitAnimations];
}

- (void) makeLocationPopup {
	TTStyle *popupStyle = [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:10] next:
						   [TTShadowStyle styleWithColor:[UIColor grayColor] 
													blur:4.0 
												  offset:CGSizeMake(4.0,4.0) next:
							[TTLinearGradientFillStyle styleWithColor1:[UIColor colorWithRed:0.98 green:0.99 blue:1.00 alpha:1.0] 
																color2:[UIColor colorWithRed:0.89 green:0.90 blue:0.92 alpha:1.0] next:
							 [TTSolidBorderStyle styleWithColor:[UIColor colorWithRed:0.76 green:0.77 blue:0.79 alpha:1.0] width:1.0 
														   next:nil]]]];
	
	CGRect frame = CGRectMake(12, 35, 304, 380);
    popupView = [[TTView alloc] initWithFrame:frame];
    popupView.backgroundColor = [UIColor clearColor];
    popupView.style = popupStyle;
	
	locationPopupViewController = [[LocationPopupViewController alloc] init];
	[locationPopupViewController viewWillAppear:NO];
	locationPopupViewController.tableView.frame=CGRectMake(10, 10, 280, 350);
	locationPopupViewController.tableView.backgroundColor = [UIColor clearColor];
	[popupView addSubview:locationPopupViewController.tableView];
	[locationPopupViewController viewDidAppear:NO];	
	[locationPopupViewController.tableView sizeToFit];
	popupView.height = locationPopupViewController.tableView.height;
	locationPopupViewController.tableView.hidden = YES;
	
	UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage *closeImage = [UIImage imageNamed:@"red-x.png"];
	closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
	closeButton.frame = CGRectMake(285, -closeImage.size.height/2, closeImage.size.width, closeImage.size.height);
	[closeButton setImage:closeImage forState:UIControlStateNormal];
	[closeButton addTarget:self action:@selector(closeLocationPopup) forControlEvents:UIControlEventTouchUpInside];
	[popupView addSubview:closeButton];
}

- (void) closeLocationPopup {
	CGRect closedDownFrame = CGRectMake(self.currentlyVisibleMarker.position.x, self.currentlyVisibleMarker.position.y, 0, 0);
	
	locationPopupViewController.tableView.hidden = YES;
	
	[UIView beginAnimations:kAnimationClosePopup context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	popupView.frame = closedDownFrame;
	[UIView commitAnimations];
}

- (void) animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	if([animationID isEqualToString:kAnimationClosePopup]) {
		[popupView removeFromSuperview];
	} else if([animationID isEqualToString:kAnimationOpenPopup]) {
		locationPopupViewController.tableView.hidden = NO;
	}
}
												
#pragma mark -
#pragma mark Drawer view

- (IBAction) toggleDrawerView {
	
	CGRect newFrame = [self.drawerView frame];
	if(drawerViewVisible) {
		newFrame.origin.y += 235;
	} else {
		newFrame.origin.y -= 235;
	}
	drawerViewVisible = !drawerViewVisible;
	[self.mapView setNeedsDisplay];
	
	[UIView beginAnimations:nil context:nil];
	[self.drawerView setFrame:newFrame];
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark Location UI status

- (void) setLocationState: (kLocationState) state {
	locationState = state;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.30];
	
	if(state == kLocationCancelled) {
		[self.locationSearchActivity stopAnimating];
		self.locationCrosshairButton.hidden = NO;
	} else if (state == kLocationSearching) {
		[self.locationSearchActivity startAnimating];
		self.locationCrosshairButton.hidden = YES;
	} else if (state == kLocationTracking) {
		[self.locationSearchActivity stopAnimating];
		self.locationCrosshairButton.hidden = NO;
	}
	
	[UIView	commitAnimations];
}

#pragma mark -
#pragma mark Core Location handling

- (IBAction) findMe {
	if(drawerViewVisible) {
		[self toggleDrawerView];
	}
	
	if (locationState == kLocationVisible) {
		mapView.contents.mapCenter = currentLocation;
		[self setLocationState:kLocationTracking];
	} else if (locationState == kLocationCancelled) {
		[self setLocationState:kLocationSearching];
		
		if(locationManager == nil) {
			locationManager = [[CLLocationManager alloc] init];
			locationManager.delegate = self; 
			locationManager.desiredAccuracy = kCLLocationAccuracyBest;
			
			// TODO: release somewhere!
		}
		
		[locationManager startUpdatingLocation];
		
		locationTimeoutTimer = [[NSTimer scheduledTimerWithTimeInterval:60
																 target:self 
															   selector:@selector(locationTimedOut:) 
															   userInfo:nil 
																repeats:NO] retain];
	}		
}

- (IBAction) cancelFindMe {
	[locationManager stopUpdatingLocation];
	
	[self stopLocationTimeoutTimer];
	
	[self setLocationState:kLocationCancelled];
	
	[[mapView markerManager] removeMarker:currentLocationMarker];
	[[mapView markerManager] removeMarker:accuracyCircleMarker];
	
	[accuracyCircleMarker release];
	accuracyCircleMarker = nil;
	[currentLocationMarker release];
	currentLocationMarker = nil;
}

- (void)locationTimedOut:(NSTimer*)theTimer {

	[self cancelFindMe];
	[self showErrorAlertWithTitle:NSLocalizedString(@"Can't find location", nil)
						  message:NSLocalizedString(@"Your location can't be found right now. Please try again later.", nil) 
			   dismissButtonLabel:NSLocalizedString(@"OK", nil)];
	[self stopLocationTimeoutTimer];
}

- (void) stopLocationTimeoutTimer {
	if (locationTimeoutTimer != nil) {
		[locationTimeoutTimer invalidate];
		[locationTimeoutTimer release];
		locationTimeoutTimer = nil;
	}	
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSInteger errorCode = [error code];
	if (errorCode ==  kCLErrorLocationUnknown) {
		// do nothing, location manager will keep trying
		// timeout handler will cancel if no location is found after looking for a while
	} else if (errorCode == kCLErrorDenied) {
		// TODO: ask user not to deny location?
		[self cancelFindMe];
	} else if (errorCode == kCLErrorNetwork) {
		[self showErrorAlertWithTitle:NSLocalizedString(@"Can't find location", nil)
							  message:NSLocalizedString(@"Your location can't be found right now. Please try again later.", nil) 
				   dismissButtonLabel:NSLocalizedString(@"OK", nil)];
		[self cancelFindMe];
	}
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	
	if (locationState == kLocationCancelled) return; // locationManager will sometimes deliver events even after being stopped
	
	NSTimeInterval locationAge = [[NSDate date] timeIntervalSinceDate:newLocation.timestamp];
	if (locationAge > kLocationTooOld) return;
	
	[self stopLocationTimeoutTimer];
	
	currentLocation = newLocation.coordinate;
	accuracy = newLocation.horizontalAccuracy;

#if TARGET_IPHONE_SIMULATOR
	NSLog(@"Setting dummy location for simulator");
	// manually set a location & accuracy for testing on the simulator
	currentLocation.latitude = 51.513825;
	currentLocation.longitude = -0.111070;
	accuracy = 100; // meters
#endif
	
	NSLog(@"accuracy = %f meters", accuracy);
	
	// TODO: do nothing if accuracy is too low?
	
	if ((currentLocation.latitude > coverageTopLeft.latitude) || 
		(currentLocation.latitude < coverageBottomRight.latitude) ||
		(currentLocation.longitude < coverageTopLeft.longitude) ||
		(currentLocation.longitude > coverageBottomRight.longitude)) {
		
		[self cancelFindMe];
		[self showErrorAlertWithTitle:NSLocalizedString(@"Out of Cycle Hire area", nil)
							  message:NSLocalizedString(@"You're currently outside the area covered by the London Cycle Hire scheme. \n If you're heading somewhere specific, try to look for bikes around a station or landmark, or browse the map.",nil)
				   dismissButtonLabel:NSLocalizedString(@"OK", nil)];
		
		return;
	}

	if(locationState != kLocationVisible) { // don't compete with the user scrolling around the map
		
		mapView.contents.mapCenter = currentLocation;
		
		// TODO: can we zoom using zoomWithLatLngBoundsNorthEast:SouthWest: instead of this hack below?
		
		// TODO: calculate the magic numbers below automatically:
		// 16 = maximum zoom
		// 9.578128403 = log2 ( 320 * metersPerPixelAtMaximumZoom )
		mapView.contents.zoom = 16 - (log2(2*accuracy) - 9.578128403);
		[self afterMapZoom:mapView byFactor: 0.0 near:CGPointZero];
	}
	
	UIImage *circleImage = [self makeAccuracyMarkerImage];
	
	if(accuracyCircleMarker == nil) {
		accuracyCircleMarker = [[RMMarker alloc] initWithUIImage:circleImage];
		[[mapView markerManager] addMarker:accuracyCircleMarker AtLatLong:currentLocation];
	} else {
		[accuracyCircleMarker replaceUIImage:circleImage];
		[[mapView markerManager] moveMarker:accuracyCircleMarker AtLatLon:currentLocation];
	}
	
	if (currentLocationMarker == nil) {
		UIImage *currentLocationMarkerImage = [UIImage imageNamed:@"you-are-here.png"];
		currentLocationMarker = [[RMMarker alloc] initWithUIImage:currentLocationMarkerImage anchorPoint:CGPointMake(0.5, 1.0)];
		[[mapView markerManager] addMarker:currentLocationMarker AtLatLong:currentLocation];
	} else {
		[[mapView markerManager] moveMarker:currentLocationMarker AtLatLon:currentLocation]; 
	}

	if (locationState == kLocationSearching) {
		[self setLocationState:kLocationTracking];		
	}
}

- (UIImage *)makeAccuracyMarkerImage {
	// TODO: return an empty image if circle diameter is too small
	
	NSInteger accuracyInPixels = accuracy / [[mapView contents] metersPerPixel];
	CGFloat squareSide = 2*(accuracyInPixels+kAccuracyCircleStrokeWidth);
	UIGraphicsBeginImageContext(CGSizeMake(squareSide, squareSide));		
	CGContextRef context = UIGraphicsGetCurrentContext();		
	UIGraphicsPushContext(context);								

	CGContextAddArc(context, 
					(CGFloat) squareSide/2, 
					(CGFloat) squareSide/2, 
					(CGFloat) accuracyInPixels, 
					0.0, 2*M_PI, 0);
	CGContextSetLineWidth (context, kAccuracyCircleStrokeWidth);
	CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
	CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.3);
	CGContextDrawPath(context, kCGPathFillStroke);
	UIGraphicsPopContext();								
	UIImage *circleImage= UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return circleImage;
}

- (void) saveMapState {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setDouble:[[mapView contents] mapCenter].latitude forKey:kLastLocationLatKey];
	[defaults setDouble:[[mapView contents] mapCenter].longitude forKey:kLastLocationLongKey];
	[defaults setFloat:[[mapView contents] zoom] forKey:kLastLocationZoomKey];	
	
	[cycleHireLocations saveFavouriteLocations];
}	

#pragma mark -
#pragma mark Navigation 

- (IBAction) showStationsList {
	if(self.stationsViewController == nil) {
		self.stationsViewController = 
			[[StationsViewController alloc] initWithNibName:@"StationsViewController" bundle:nil];
	}
	[self.navigationController pushViewController:self.stationsViewController animated:YES];
}

- (void) centerOnPOICoordinate: (CLLocationCoordinate2D) coordinate withZoom: (float) zoom {
	[self toggleDrawerView];
	if(locationState == kLocationTracking) {
		locationState = kLocationVisible;
	}
	[self.navigationController popToRootViewControllerAnimated:YES];
	self.mapView.contents.mapCenter = coordinate;
	[self zoomAndUpdate:zoom];
}

- (void) centerOnLat: (CLLocationDegrees) latitude Long: (CLLocationDegrees) longitude withZoom: (float) zoom {
	CLLocationCoordinate2D coord;
	coord.latitude = latitude;
	coord.longitude = longitude;
	[self centerOnPOICoordinate:coord withZoom:zoom];
}

- (void) centerOnLat: (CLLocationDegrees) latitude Long: (CLLocationDegrees) longitude withZoom: (float) zoom 
	   andDropMarker:(NSString*) markerType withTitle:(NSString*) markerTitle atPostcode:(NSString *)postcode {
	
	NSString *markerImageFilename = [NSString stringWithFormat:@"marker-%@.png", markerType];
	if(poiMarker == nil) {
		poiMarker = [[RMMarker alloc] initWithUIImage:[UIImage imageNamed:markerImageFilename] anchorPoint:CGPointMake(0.5, 1.0)];
	} else {
		[poiMarker replaceUIImage:[UIImage imageNamed:markerImageFilename] anchorPoint:CGPointMake(0.5, 1.0)];
	}
	
	CLLocationCoordinate2D markerPosition;
	if(postcode == nil) {
		markerPosition.latitude = latitude;
		markerPosition.longitude = longitude;
	} else {
		markerPosition = [postcodes coordinateForPostcode:postcode];
	}
	
	if(markerTitle != nil) {
		[poiMarker changeLabelUsingText:markerTitle  
								   font:[UIFont fontWithName:@"Marker Felt" size:18]
						foregroundColor:[UIColor whiteColor]
						backgroundColor:[UIColor colorWithWhite:0.0 alpha:0.4]];
		poiMarker.label.layer.cornerRadius = 4;
	}
	
	[mapView.markerManager addMarker:poiMarker AtLatLong:markerPosition];
	
	[self centerOnLat:latitude Long:longitude withZoom:zoom];
}

- (void) openCycleHireLocationWithId: (NSString*) locationId {
	
	NSString *decodedLocationId = [locationId stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
	RMMarker *locationMarker = [markersForLocations objectForKey:decodedLocationId];
	CycleHireLocation *locationToOpen = (CycleHireLocation *) locationMarker.data;
	
	[self.navigationController popToRootViewControllerAnimated:YES];
	self.mapView.contents.mapCenter = locationToOpen.coordinate;
	
	[self tapOnMarker:locationMarker onMap:mapView];
}

- (IBAction) showAttractionsList {
	[[TTNavigator navigator] openURLAction:[[TTURLAction actionWithURLPath:@"cyclehire://attractions/"] applyAnimated:YES]];
}

- (IBAction) showFavouritesList {
	TTURLAction *openFavourites = [[[TTURLAction actionWithURLPath:@"cyclehire://favourites/dummy"] 
									applyAnimated:YES]
								   applyQuery:[NSDictionary dictionaryWithObject:cycleHireLocations forKey:@"locations"]];
	
	[[TTNavigator navigator] openURLAction:openFavourites];
}

- (IBAction) infoButtonTapped {
	[[TTNavigator navigator] openURLAction:[[TTURLAction actionWithURLPath:@"cyclehire://information/"] applyAnimated:YES]];
	
	//	printf([[NSString stringWithFormat:@"%f,%f,%f\n", mapView.contents.mapCenter.latitude, mapView.contents.mapCenter.longitude, mapView.contents.zoom] cString]);
}

#pragma mark -
#pragma mark Postcode Search

- (IBAction) showPostcodeEntryAlert {
	UIAlertView *postcodeEntryAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter a postcode:", nil) 
																 message:@"\n\n"
																delegate:self 
													   cancelButtonTitle:NSLocalizedString(@"Cancel",nil) 
													   otherButtonTitles:NSLocalizedString(@"Search",nil), nil];
		
	UITextField *postcodeField = [[UITextField alloc] initWithFrame:CGRectMake(16,50,252,42)];
	postcodeField.tag = 101;
	postcodeField.font = [UIFont systemFontOfSize:32];
	postcodeField.textAlignment = UITextAlignmentCenter;
	postcodeField.keyboardType = UIKeyboardTypeASCIICapable;
	postcodeField.keyboardAppearance = UIKeyboardAppearanceAlert;
	postcodeField.returnKeyType = UIReturnKeySearch;
	postcodeField.autocorrectionType = UITextAutocorrectionTypeNo;
	postcodeField.delegate = self;
	postcodeField.borderStyle =	UITextBorderStyleRoundedRect;
	[postcodeField becomeFirstResponder];
	[postcodeEntryAlert addSubview:postcodeField];
	
	[postcodeEntryAlert setTransform:CGAffineTransformMakeTranslation(0,109)];
	[postcodeEntryAlert show];
	[postcodeEntryAlert release];
	[postcodeField release];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	// This will turn all characters into capitals and will only allow entry of letters, numbers & spaces
	
	NSString *capitalizedString = [string uppercaseString];
	NSCharacterSet *validPostcodeCharacters = [NSCharacterSet characterSetWithCharactersInString:
											   @"ABCEDFGHIJKLMNOPQURSTUVWXYZ0123456789 "];
	NSMutableString *filteredString = [[NSMutableString alloc] initWithCapacity:[capitalizedString length]];
	
	for (NSUInteger i = 0; i < [capitalizedString length]; i++) {
		if ([validPostcodeCharacters characterIsMember:[capitalizedString characterAtIndex:i]]) {
			[filteredString appendFormat:@"%C", [capitalizedString characterAtIndex:i]];
		}
	}
	
	textField.text = [textField.text stringByReplacingCharactersInRange:range withString:filteredString];
	[filteredString release];
	return NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	UIAlertView *parentAlertView = (UIAlertView *) textField.superview;
	[parentAlertView dismissWithClickedButtonIndex:parentAlertView.firstOtherButtonIndex animated:YES];
	
	return YES;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
	
	UIView *postcodeFieldView = [alertView viewWithTag:101];	
	if (postcodeFieldView != nil && [postcodeFieldView isKindOfClass:[UITextField class]]) {
		UITextField *postcodeField = (UITextField*)postcodeFieldView;
		[postcodeField resignFirstResponder]; // this needs to happen before hiding the alert view

		if (buttonIndex == alertView.cancelButtonIndex) {
			return;
		} else {
			[self postcodeSearch:postcodeField.text];
		}
	}
}

- (void) postcodeSearch:(NSString*)postcode {
	NSString *normalizedPostcode = [postcode stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	if (![PostcodeDatabase isValidPostcode:normalizedPostcode]) {
		[self showErrorAlertWithTitle:NSLocalizedString(@"Invalid postcode", nil) 
							  message:NSLocalizedString(@"You may have made a typing mistake or typed an incomplete postcode.", nil) 
				   dismissButtonLabel:NSLocalizedString(@"OK", nil)];
		return;
	}
		
	CLLocationCoordinate2D postcodeCoord = [postcodes coordinateForPostcode:normalizedPostcode];
	if (CLIsValidCoordinate(postcodeCoord)) {
		[self centerOnLat:postcodeCoord.latitude Long:postcodeCoord.longitude withZoom:16
			andDropMarker:@"pin" withTitle:postcode atPostcode:nil];
	} else {
		[self showErrorAlertWithTitle:NSLocalizedString(@"Out of Cyce Hire area", nil) 
							  message:NSLocalizedString(@"This postcode is located outside the area covered by the Cycle Hire scheme.", nil) 
				   dismissButtonLabel:NSLocalizedString(@"OK", nil)];
	}
}

#pragma mark -
#pragma mark Directons handling

- (void) directionsFromLat:(CLLocationDegrees) latitude Long:(CLLocationDegrees) longitude {
	directionsStartingPoint.latitude = latitude;
	directionsStartingPoint.longitude = longitude;
		
	[self closeLocationPopup];

	if (CLIsValidCoordinate(directionsFinishPoint)) {
		[self updateDirections];
	}
}

- (void) directionsToLat:(CLLocationDegrees) latitude Long:(CLLocationDegrees) longitude {
	directionsFinishPoint.latitude = latitude;
	directionsFinishPoint.longitude = longitude;
	
	[self closeLocationPopup];
	
	if (CLIsValidCoordinate(directionsStartingPoint)) {
		[self updateDirections];
	}
}

- (IBAction) updateDirections {
	if(planner == nil) {
		planner = [[CycleStreetsPlanner alloc] initWithAPIkey:CYCLESTREETS_API_KEY delegate:self];
	}
	[planner requestDirectionsFrom:directionsStartingPoint to:directionsFinishPoint];
	[self setDirectionsState:kDirectionsRequested];
}

- (IBAction) cancelDirections {
	if(directionsState == kDirectionsRequested) {
		[planner cancelPendingRequest];
	} else if (directionsState == kDirectionsVisible) {
		[directionsPath removeFromSuperlayer];
	}
	[self setDirectionsState:kDirectionsHidden];
	
	directionsStartingPoint = CLInvalidCoordinate();
	directionsFinishPoint = CLInvalidCoordinate();
}

- (void) cycleStreetsPlanner: (CycleStreetsPlanner *)planner didFindRoute: (CycleStreetsRoute *) route {
	
	NSLog(@"numberOfWaypoints=%d", route.numberOfWaypoints);
	
	if(directionsPath != nil) {
		[directionsPath removeFromSuperlayer];
		[directionsPath release];
	}
	
	directionsPath = [[RMPath alloc] initForMap:mapView];
	[directionsPath setLineColor:[UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:0.5f]];
	[directionsPath setFillColor:[UIColor clearColor]];
	[directionsPath setLineWidth:8.0f];
	[directionsPath setDrawingMode:kCGPathStroke];
	[directionsPath setLineJoin:kCGLineJoinRound];
	[directionsPath setLineCap:kCGLineCapRound];

	CLLocationCoordinate2D northEast; northEast.latitude =-MAXFLOAT; northEast.longitude =-MAXFLOAT;
	CLLocationCoordinate2D southWest; southWest.latitude = MAXFLOAT; southWest.longitude = MAXFLOAT;
	
	for (NSUInteger i = 0; i<route.numberOfWaypoints; i++) {
		CLLocationCoordinate2D waypoint = [route waypointAtIndex:i];
		
		// calculate bounding rectangle for path
		northEast.latitude = MAX(northEast.latitude, waypoint.latitude);
		northEast.longitude = MAX(northEast.longitude, waypoint.longitude);

		southWest.latitude = MIN(southWest.latitude, waypoint.latitude);
		southWest.longitude = MIN(southWest.longitude, waypoint.longitude);
		
		[directionsPath addLineToLatLong:waypoint];
	}	
	
	NSLog(@"NE=(%f,%f), SW=(%f,%f)", northEast.latitude, northEast.longitude, southWest.latitude, southWest.longitude);
	
	[mapView.contents.overlay addSublayer:directionsPath];
	
	NSLog(@"Zoom before:%f", mapView.contents.zoom);
	
	[mapView.contents zoomWithLatLngBoundsNorthEast:northEast SouthWest:southWest];
	
	NSLog(@"Zoom after:%f", mapView.contents.zoom);
	
	if (mapView.contents.zoom > mapView.contents.maxZoom) {
		// zoomWithLatLngBoundsNorthEast seems to ignore maximum zoom
		[self zoomAndUpdate:mapView.contents.maxZoom];
	}
	NSLog(@"Zoom after2:%f", mapView.contents.zoom);

	[mapView.contents zoomWithRMMercatorRectBounds:mapView.contents.projectedBounds]; // this causes the map to redisplay!
	
	float distanceInKilometers = (float)route.distanceInMeters/1000;
	float timeInMinutes = (float)route.timeInSeconds/60;
	if(timeInMinutes < 1.0) {
		timeInMinutes = 1.0;
	}
	NSUInteger timeInMinutesRounded = (NSUInteger) roundf(timeInMinutes);
	
	NSString *distanceUnits;
	float distanceValue;
	if ([CycleStreetsPlanner shouldUseMilesForDistances]) {
		distanceUnits = @"miles";
		distanceValue = distanceInKilometers * 0.621;
	} else {
		distanceUnits = NSLocalizedString(@"km", "kilometers");
		distanceValue = distanceInKilometers;
	}
	
	NSString *minutesLocalized = NSLocalizedString(@"minutes", nil);
	
	self.directionsLabel.text = [NSString stringWithFormat:@"%.2f %@ - %d %@", 
								 distanceValue, distanceUnits, timeInMinutesRounded, minutesLocalized];
	[self setDirectionsState:kDirectionsVisible];
}

- (void) cycleStreetsPlanner: (CycleStreetsPlanner *)planner didFailWithError:(NSError *)error {
	
	[self showErrorAlertWithTitle:NSLocalizedString(@"Cannot Get Directions", nil)
						message:[error localizedDescription] 
			   dismissButtonLabel:@"OK"];
	[self setDirectionsState:kDirectionsHidden];
	// TODO: give some way to retry in this case?
}

#pragma mark -
#pragma mark Directions UI status

- (void) setDirectionsState: (kDirectionsState) state {
	directionsState = state;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.30];
	
	if(state == kDirectionsHidden) {
		[self.directionsActivity stopAnimating];
		self.directionsOverlayView.hidden = YES;
	} else if (state == kDirectionsRequested) {
		self.directionsActivity.hidden = NO;
		[self.directionsActivity startAnimating];
		self.directionsOverlayView.hidden = NO;
		self.directionsLabel.text = NSLocalizedString(@"Getting directions ...", nil);
	} else if (state == kDirectionsVisible) {
		[self.directionsActivity stopAnimating];
	}
	
	[UIView	commitAnimations];
}

#pragma mark -
#pragma mark Timer 

- (IBAction) timerButtonTapped {	
	if (drawerViewVisible) {
		[self toggleDrawerView];
	}
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Remind me to return the bike in:", nil) 
															 delegate:nil 
													cancelButtonTitle:NSLocalizedString(@"Cancel", nil) 
											   destructiveButtonTitle:nil 
													otherButtonTitles:NSLocalizedString(@"25 minutes", nil),
								  NSLocalizedString(@"55 minutes", nil), 
								  NSLocalizedString(@"1 hour 25 minutes", nil), nil];
	[actionSheet showInView:mapView];	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == actionSheet.cancelButtonIndex) return;
	
}

#pragma mark -
#pragma mark Zoom/move workarounds

- (void) zoomAndUpdate: (float) newZoom {
	mapView.contents.zoom = newZoom;
	[self afterMapZoom:mapView byFactor: 0.0 near:CGPointZero];
}

#pragma mark -
#pragma mark Alerts

- (void)showErrorAlertWithTitle: (NSString*) title message: (NSString*) message dismissButtonLabel:(NSString*) label {

	UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:title 
														 message:message 
														delegate:nil
											   cancelButtonTitle:label 
											   otherButtonTitles:nil];
	[errorAlert show];
	[errorAlert release];
	
}

@end

