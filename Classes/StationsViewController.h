//
//  StationsViewController.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 18/03/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StationsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	NSInteger stationType;
	
	UITableView *stationsTableView;

	NSArray *stationsLU;
	NSArray *stationsNR;
	NSMutableArray *AZArray;
}

@property (nonatomic, retain) IBOutlet UITableView *stationsTableView;

- (IBAction)stationTypeChanged:(id)sender;
- (void) loadStationData;
- (NSArray *) indexedStationArrayFromCSV: (NSString *) csvName;

@end
