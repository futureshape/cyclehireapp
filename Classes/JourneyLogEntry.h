//
//  JourneyLogEntry.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 23/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JourneyLogEntry : NSObject {
	NSString *startStation;
	NSDate *startDate;
	NSString *endStation;
	NSDate *endDate;
	NSString *cost;	
}

@property (nonatomic, retain) NSString *startStation;
@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSString *endStation;
@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSString *cost;	

-(id) initEntryStartingFrom: (NSString *) _startStation 
					 onDate: (NSDate *) _startDate
					goingTo: (NSString *) _endStation
				  onEndDate: (NSDate *) _endDate
					costing: (NSString *) _cost;
@end
