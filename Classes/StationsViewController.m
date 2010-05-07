//
//  StationsViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 18/03/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "StationsViewController.h"
#import	"MapViewController.h"
#import "parseCSV.h"

#define kStationTypeLU 0	// London Underground
#define kStationTypeNR 1	// National Rail

@implementation StationsViewController

@synthesize stationsTableView;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/


- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.title = NSLocalizedString(@"Stations", nil);

	AZArray = [[NSMutableArray alloc] initWithCapacity:26];
	for (int i=0; i < 26; i++) {
		unichar label = 'A' + i;
		[AZArray addObject:[NSString stringWithCharacters:&label length:1]]; 
	}
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;
	[self.stationsTableView deselectRowAtIndexPath:[self.stationsTableView indexPathForSelectedRow] animated:NO];
	
	if (stationsNR == nil) {
		[self loadStationData];
	}
 }

- (void) loadStationData {
	stationsLU = [self indexedStationArrayFromCSV:@"underground"];	
	stationsNR = [self indexedStationArrayFromCSV:@"rail"];

	[stationsLU retain];
	[stationsNR retain];
}

- (NSArray *) indexedStationArrayFromCSV: (NSString *) csvName {
	CSVParser *parser = [CSVParser new];
	
	NSString *csvPath = [[NSBundle mainBundle] pathForResource:csvName ofType:@"csv"]; 
	[parser openFile: csvPath];
	NSArray *stations = [parser parseFile];
	[parser closeFile];
	
	NSMutableArray *stationsIndexed = [NSMutableArray arrayWithCapacity:26];
	for (int i=0; i < 26; i++) {
		NSMutableArray *letterArray = [NSMutableArray arrayWithCapacity:1];
		[stationsIndexed insertObject:letterArray atIndex:i];
	}
	
	for (NSArray *stationRecord in stations) {
		NSString *stationName = [stationRecord objectAtIndex:0];
		unichar initialLetter = [stationName characterAtIndex:0];
		NSUInteger index = initialLetter - 'A';
		
		NSMutableArray *letterArray = [stationsIndexed objectAtIndex:index];
		[letterArray addObject:stationRecord];
	}
	[parser release];
	
	return stationsIndexed;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	if(self.navigationController.topViewController != self) {
		[stationsNR release];
		stationsNR = nil;
		[stationsLU release];
		stationsLU = nil;	
	}
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (stationType == kStationTypeLU ? [stationsLU count] : [stationsNR count]);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSArray *currentStationsList = (stationType == kStationTypeLU ? stationsLU : stationsNR);
    return [[currentStationsList objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	NSArray *currentStationsList = (stationType == kStationTypeLU ? stationsLU : stationsNR);
	NSArray *currentSectionList = [currentStationsList objectAtIndex:[indexPath indexAtPosition:0]];
	cell.textLabel.text = [(NSArray *)[currentSectionList objectAtIndex:[indexPath indexAtPosition:1]] objectAtIndex:0];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *currentStationsList = (stationType == kStationTypeLU ? stationsLU : stationsNR);
	NSArray *currentSectionList = [currentStationsList objectAtIndex:[indexPath indexAtPosition:0]];
	NSArray *stationRecord = [currentSectionList objectAtIndex:[indexPath indexAtPosition:1]];
	
	CLLocationCoordinate2D stationCoordinate;
	stationCoordinate.latitude = [(NSString *)[stationRecord objectAtIndex:1] doubleValue];
	stationCoordinate.longitude = [(NSString *)[stationRecord objectAtIndex:2] doubleValue];

	MapViewController *mapViewController = [[self.navigationController viewControllers] objectAtIndex:0];
	[mapViewController centerOnPOICoordinate:stationCoordinate withZoom:15.0]; // TODO: determine right zoom
//	[mapViewController centerOnLat:stationCoordinate.latitude Long:stationCoordinate.longitude withZoom:16
//					 andDropMarker:(stationType == kStationTypeLU ? @"underground" : @"rail") 
//						 withTitle:(NSString *)[stationRecord objectAtIndex:0] 
//						atPostcode:nil];
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [AZArray objectAtIndex:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return AZArray;
}

- (IBAction)stationTypeChanged:(id)sender {
	UISegmentedControl *stationTypeSelector = (UISegmentedControl *)sender;
	stationType = stationTypeSelector.selectedSegmentIndex;
	[self.stationsTableView reloadData];
}

- (void)dealloc {
    [super dealloc];
	[stationsNR release];
	[stationsLU release];
}

@end

