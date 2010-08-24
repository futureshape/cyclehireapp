//
//  AccountScraper.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 23/08/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "AccountScraper.h"


@implementation AccountScraper

@synthesize delegate;
@synthesize accountBalance;
@synthesize journeyLog;
@synthesize totalCyclingTime;
@synthesize uniqueDockingStationsVisited;

- (id) init {
	if (self == [super init]) {
		requestQueue = [[ASINetworkQueue alloc] init];
		
		df = [[NSDateFormatter alloc] init];
		[df setDateFormat:@"dd MMM yyyy HH:mm"];
		[df setLenient:YES];
	}
	return self;
}

- (void) startScraping {
	[self stopScraping];
	NSLog(@"AccountScraper - Loading homepage");	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:CYCLE_HIRE_LOGIN_PAGE]];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(loadingHomepageFinished:)];
	[requestQueue addOperation:request];
	[requestQueue go];
}

- (void)loadingHomepageFinished:(ASIHTTPRequest *)_request{
	NSLog(@"AccountScraper - Homepage loaded");
	NSString *responseString = [_request responseString];
	
	NSArray *captureComponents = [responseString arrayOfCaptureComponentsMatchedByRegex:CSRF_REGEX];
	
	if([captureComponents count] > 0 && 
	   [[captureComponents objectAtIndex:0] count] == 2 &&
	   ![[[captureComponents objectAtIndex:0] objectAtIndex:1] isEqualToString:@""]) {
		NSString *CSRF = [[captureComponents objectAtIndex:0] objectAtIndex:1];
		NSLog(@"AccountScraper - Found CSRF token: %@", CSRF);
		[self sendLoginRequestWithCSRF:CSRF];
	} else {
		[delegate scraperDidFailWithError:[NSError errorWithDomain:kAccountScraperErrorDomain 
															  code:kASNoCsrfError 
														  userInfo:nil]];
	}
}

- (void) sendLoginRequestWithCSRF: (NSString *) CSRF {
	NSLog(@"AccountScraper - Logging in");
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:CYCLE_HIRE_LOGIN_PAGE]];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(loginRequestFinished:)];
	[request setPostValue:[[NSUserDefaults standardUserDefaults] objectForKey:kEmailKey] forKey:@"login[Email]"]; 
	[request setPostValue:[[NSUserDefaults standardUserDefaults] objectForKey:kPasswordKey] forKey:@"login[Password]"];
	[request setPostValue:CSRF forKey:@"login[_csrf_token]"];
	[requestQueue addOperation:request];
	[requestQueue go];
}

- (void)loginRequestFinished:(ASIHTTPRequest *)_request{
	NSString *postLoginURL = [_request.url absoluteString];
	NSLog(@"AccountScraper - Login request finished on page: %@", postLoginURL);
	
	if ([postLoginURL isEqualToString:CYCLE_HIRE_ACCOUNT_HOME]) {
		// login worked 
		[self loadCycleHireActivityLog];
	} else {
		// have been redirected somewhere else - error (most likely wrong password - extract?)
		[delegate scraperDidFailWithError:[NSError errorWithDomain:kAccountScraperErrorDomain 
															  code:kASLoginFailedError 
														  userInfo:nil]];
	}
}	

- (void) loadCycleHireActivityLog {
	NSLog(@"AccountScraper - Loading activity log");	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:CYCLE_HIRE_ACTIVITY_LOG]];
	[request setDelegate:self];
	[request setDidFinishSelector:@selector(loadingActivityLogFinished:)];
	[requestQueue addOperation:request];
	[requestQueue go];
}

- (void)loadingActivityLogFinished:(ASIHTTPRequest *)_request{
	NSLog(@"AccountScraper - Activity log loaded");
	NSString *responseString = [_request responseString];
	
	@try {
		NSArray *split1 = [responseString componentsSeparatedByString:@"<tbody>"];
		NSArray *split2 = [[split1 objectAtIndex:1] componentsSeparatedByString:@"</tbody>"];
		NSString *tableString = [split2 objectAtIndex:0];
		NSMutableString *tableString2 = [NSMutableString stringWithFormat:@"<tbody>%@</tbody>", tableString];
		[tableString2 replaceOccurrencesOfString:@"&pound;"
									  withString:@""
										 options:NSCaseInsensitiveSearch
										   range:NSMakeRange(0, [tableString2 length])];
		[tableString2 replaceOccurrencesOfString:@"<br/>"
									  withString:@" "
										 options:NSCaseInsensitiveSearch
										   range:NSMakeRange(0, [tableString2 length])];
		TTXMLParser *parser = [[TTXMLParser alloc] initWithData:[tableString2 dataUsingEncoding:NSUTF8StringEncoding]];
		[parser setTreatDuplicateKeysAsArrayItems:YES];
		[parser parse];
		
		NSArray *rows = [parser.rootObject objectForKey:@"tr"];
		
		NSMutableArray *journeyLogEntries = [NSMutableArray arrayWithCapacity:[rows count]];
		NSMutableDictionary *dockingStationsVisited = [NSMutableDictionary dictionaryWithCapacity:[rows count]*2];
		self.totalCyclingTime = 0;
		
		for (NSDictionary *rowEntry in rows) {
			NSArray *rowCells = [rowEntry objectForKey:@"td"];
			
			if ([rowCells count] == 6) {
				NSString *eventType = [[[rowCells objectAtIndex:4] objectForXMLNode] stringByTrimmingCharactersInSet:
									   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				
				if ([[eventType lowercaseString] isEqualToString:@"hire"]) {
					NSString *startDateString = [[[rowCells objectAtIndex:0] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSDate *startDate = [df dateFromString:startDateString];

					NSString *endDateString	  = [[[rowCells objectAtIndex:1] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSDate *endDate = [df dateFromString:endDateString];

					NSString *startStation	  = [[[rowCells objectAtIndex:2] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSString *endStation	  = [[[rowCells objectAtIndex:3] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];
					NSString *cost			  = [[[rowCells objectAtIndex:5] objectForXMLNode] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceAndNewlineCharacterSet]];

					[journeyLogEntries addObject:[[JourneyLogEntry alloc] initEntryStartingFrom:startStation
																						 onDate:startDate
																						goingTo:endStation 
																					  onEndDate:endDate 
																						costing:cost]];
					
					if ([dockingStationsVisited objectForKey:startStation] == nil) {
						[dockingStationsVisited setObject:startDate forKey:startStation]; 
					} else {
						NSDate *lastVisited = [dockingStationsVisited objectForKey:startStation];
						if ([startDate timeIntervalSinceDate:lastVisited] > 0) {
							[dockingStationsVisited setObject:startDate forKey:startStation];
						}
					}

					if ([dockingStationsVisited objectForKey:endStation] == nil) {
						[dockingStationsVisited setObject:endDate forKey:endStation]; 
					} else {
						NSDate *lastVisited = [dockingStationsVisited objectForKey:endStation];
						if ([endDate timeIntervalSinceDate:lastVisited] > 0) {
							[dockingStationsVisited setObject:endDate forKey:endStation];
						}
					}
					
					self.totalCyclingTime += [endDate timeIntervalSinceDate:startDate];
					
				}
			} else if ([rowCells count] == 3) {
				NSString *eventType = [[[rowCells objectAtIndex:1] objectForXMLNode] stringByTrimmingCharactersInSet:
									   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				if ([[eventType lowercaseString] isEqualToString:@"balance"]) {
					self.accountBalance = [[[rowCells objectAtIndex:2] objectForXMLNode] stringByTrimmingCharactersInSet:
											[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				}
			}
		}
	
		self.journeyLog = journeyLogEntries;
		self.uniqueDockingStationsVisited = dockingStationsVisited;
		
		[delegate scraperDidFinishScraping];
		
	}
	@catch (NSException *exception) {
		[delegate scraperDidFailWithError:[NSError errorWithDomain:kAccountScraperErrorDomain 
															  code:kASParsingFailed
														  userInfo:nil]];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)_request {
	[delegate scraperDidFailWithError:_request.error];
}

- (void) stopScraping {
	[requestQueue cancelAllOperations];
}

- (void) dealloc {
	[super dealloc];
	[requestQueue release];
	[df release];
}

@end
