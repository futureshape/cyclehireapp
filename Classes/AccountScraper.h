//
//  AccountScraper.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 23/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Three20/Three20.h"
#import <extThree20XML/extThree20XML.h>

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

#import "RegexKitLite.h"

#import "JourneyLogEntry.h"

#define CYCLE_HIRE_LOGIN_PAGE		@"https://web.barclayscyclehire.tfl.gov.uk/"
#define CYCLE_HIRE_ACCOUNT_HOME		@"https://web.barclayscyclehire.tfl.gov.uk/account/home"
#define CYCLE_HIRE_ACTIVITY_LOG		@"https://web.barclayscyclehire.tfl.gov.uk/account/activity"
#define CSRF_REGEX					@"value=\"([a-fA-F\\d]{32})\""
#define kEmailKey					@"CycleHireEmail"
#define kPasswordKey				@"CycleHirePassword"
#define kAccountScraperErrorDomain	@"AccountScraper"

@class AccountScraper;

@protocol AccountScraperDelegate

- (void) scraperDidFinishScraping;
- (void) scraperDidFailWithError:(NSError *)error;

@end

@interface AccountScraper : NSObject {

	ASINetworkQueue *requestQueue;
	NSDateFormatter *df;
	
	id<AccountScraperDelegate> delegate;
	
	// Extracted data below:
	NSString *accountBalance;
	NSArray *journeyLog;
	NSTimeInterval totalCyclingTime;
	NSDictionary *uniqueDockingStationsVisited;
}

@property (nonatomic, retain) NSString *accountBalance;
@property (nonatomic, retain) NSArray *journeyLog;
@property (nonatomic) NSTimeInterval totalCyclingTime;
@property (nonatomic, retain) id<AccountScraperDelegate> delegate;
@property (nonatomic, retain) NSDictionary *uniqueDockingStationsVisited;

- (id) init;
- (void) startScraping;
- (void) sendLoginRequestWithCSRF: (NSString *) CSRF;
- (void) loadCycleHireActivityLog;
- (void) stopScraping;
@end

typedef enum {
	kASNoCsrfError = 0, 
	kASLoginFailedError,
	kASParsingFailed
} ASError;
