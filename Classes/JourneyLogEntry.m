//
//  JourneyLogEntry.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 23/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "JourneyLogEntry.h"

@implementation JourneyLogEntry

@synthesize startStation;
@synthesize startDate;
@synthesize endStation;
@synthesize endDate;
@synthesize cost;

-(id) initEntryStartingFrom: (NSString *) _startStation 
					 onDate: (NSDate *) _startDate
					goingTo: (NSString *) _endStation
				  onEndDate: (NSDate *) _endDate
					costing: (NSString *) _cost {

	if (self == [super init]) {
		self.startStation = _startStation;
		self.startDate = _startDate;
		self.endStation = _endStation;
		self.endDate = _endDate;
		self.cost = _cost;
	}
	
	return self;
}

@end
