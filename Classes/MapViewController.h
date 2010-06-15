//
//  MapViewController.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 17/03/2010.
//  Copyright Alexander Baxevanis 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreGraphics/CoreGraphics.h>

#ifdef __APPLE__
#include "TargetConditionals.h" // for detecting simulator
#endif

// Map
#import "RMCloudMadeMapSource.h"
#import "RMDBMapSource.h"
#import "RMMarker.h"
#import "RMPath.h"
#import "RMMarkerManager.h"
#import "RMMapView.h"

#import "LocationPopupViewController.h"
#import "CycleHireLocation.h"
#import "CycleHireLocations.h"
#import	"StationsViewController.h"
#import "LocationPopupViewController.h"
#import "CycleStreetsPlanner.h"
#import "CoreLocationAdditions.h"
#import "PostcodeDatabase.h"

#define kLastLocationLatKey		@"LastLocationLat"
#define kLastLocationLongKey	@"LastLocationLong"
#define kLastLocationZoomKey	@"LastLocationZoom"

typedef enum {
	kLocationCancelled = 1,	// No location operations in progress
	kLocationSearching,		// Looking for initial location fix
	kLocationTracking,		// Tracking after initial location fix
	kLocationVisible		// Location updating but not moving the map
} kLocationState;

typedef enum {
	kDirectionsHidden = 1,	// No directions request in progress
	kDirectionsRequested,	// Requested directions and waiting to download
	kDirectionsVisible		// Directions have been displayed
} kDirectionsState;


@interface MapViewController : UIViewController <RMMapViewDelegate,	CLLocationManagerDelegate, UIActionSheetDelegate, CycleStreetsPlannerDelegate, UITextFieldDelegate> {
	IBOutlet RMMapView * mapView;
	
	CLLocationCoordinate2D coverageTopLeft;
	CLLocationCoordinate2D coverageBottomRight;	
	
	CycleHireLocations *cycleHireLocations;

	// Location popup view
	RMMarker *currentlyVisibleMarker;
	TTView *popupView;
	NSMutableDictionary *markersForLocations;
	
	// CoreLocation handling
	CLLocationManager *locationManager;
	CLLocationCoordinate2D currentLocation;
	CLLocationAccuracy accuracy;
	NSUInteger locationState;
	NSTimer *locationTimeoutTimer;
	RMMarker *currentLocationMarker;

	// Location UI
	IBOutlet UIButton *locationCrosshairButton;
	IBOutlet UIActivityIndicatorView * locationSearchActivity;
	
	// Main drawer-style menu
	IBOutlet UIView * drawerView;
	BOOL drawerViewVisible;
	
	// Directions
	CLLocationCoordinate2D directionsStartingPoint;
	CLLocationCoordinate2D directionsFinishPoint;
	CycleStreetsPlanner *planner;
	RMPath *directionsPath;

	// Directions UI
	kDirectionsState directionsState;
	IBOutlet UIView *directionsOverlayView;
	IBOutlet UIActivityIndicatorView *directionsActivity;
	IBOutlet UILabel *directionsLabel;
	
	// Postcodes 
	PostcodeDatabase *postcodes;
	
	RMMarker *poiMarker;
													
	StationsViewController *stationsViewController;
	LocationPopupViewController *locationPopupViewController;
	
	BOOL firstAppearance;
}

@property (nonatomic, retain) IBOutlet RMMapView * mapView;
@property (nonatomic, retain) IBOutlet UIView * drawerView;

@property (nonatomic, retain) IBOutlet UIButton * locationCrosshairButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView * locationSearchActivity;

@property (nonatomic, retain) IBOutlet UIView *directionsOverlayView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *directionsActivity;
@property (nonatomic, retain) IBOutlet UILabel *directionsLabel;

@property (nonatomic, retain) StationsViewController *stationsViewController;

@property (nonatomic, retain) RMMarker *currentlyVisibleMarker;

- (void) loadCycleHireLocations;
- (IBAction)toggleDrawerView;

- (IBAction) findMe;
- (IBAction) cancelFindMe;

- (UIImage *)makeCurrentLocationMarkerImage;
- (void) makeLocationPopup;
- (void) closeLocationPopup;

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (void) stopLocationTimeoutTimer;

- (void) setLocationState: (kLocationState) state;

- (void) saveAppState;

- (IBAction) showStationsList;
- (void) centerOnPOICoordinate: (CLLocationCoordinate2D) coordinate withZoom: (float) zoom;
- (void) centerOnLat: (CLLocationDegrees) latitude Long: (CLLocationDegrees) longitude withZoom: (float) zoom 
	   andDropMarker:(NSString*) markerType withTitle:(NSString*) markerTitle atPostcode:(NSString *)postcode;
- (IBAction) showAttractionsList;
- (IBAction) showPostcodeEntryAlert;
- (IBAction) showFavouritesList;

- (void) postcodeSearch:(NSString*)postcode;

- (IBAction) infoButtonTapped;
- (IBAction) timerButtonTapped;

- (IBAction) updateDirections;
- (IBAction) cancelDirections;
- (void) setDirectionsState: (kDirectionsState) state;

- (void) zoomAndUpdate: (float) newZoom;

- (void)showErrorAlertWithTitle: (NSString*) title message: (NSString*) message dismissButtonLabel:(NSString*) label;

@end
