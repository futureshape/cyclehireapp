//
//  CycleHireAppDelegate.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 17/03/2010.
//  Copyright Alexander Baxevanis 2010. All rights reserved.
//

#import "CycleHireAppDelegate.h"
#import "MapViewController.h"
#import "AttractionListViewController.h"
#import "AttractionCategoryViewController.h"
#import "LocationPopupViewController.h"
#import "FavouritesListViewController.h"
#import "GlobalStyleSheet.h"
#import "InfoViewController.h"
#import "InfoWebViewController.h"

#import <Three20/Three20.h>

@implementation CycleHireAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
	
	[TTStyleSheet setGlobalStyleSheet:[[[GlobalStyleSheet alloc] init] autorelease]];

	TTNavigator* navigator = [TTNavigator navigator];
	navigator.persistenceMode = TTNavigatorPersistenceModeNone;
	
	TTURLMap* map = navigator.URLMap;
	[map from:@"*" toViewController:[InfoWebViewController class]];

	[map from:@"cyclehire://attractions/category/(initWithTitle:)/(attractionsCSV:)" toSharedViewController:([AttractionListViewController class])];
	[map from:@"cyclehire://attractions/" toSharedViewController:([AttractionCategoryViewController class])];
	[map from:@"cyclehire://map/" toSharedViewController:([MapViewController class])];
	
	// TODO: initWithName is dummy so we can also pass query - is there any other way?
	[map from:@"cyclehire://favourites/(initWithName:)" toSharedViewController:([FavouritesListViewController class])];

	[map from:@"cyclehire://information/" toSharedViewController:([InfoViewController class])];

	
	[navigator openURLAction:[TTURLAction actionWithURLPath:@"cyclehire://map/"]];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[[[TTNavigator navigator].URLMap objectForURL:@"cyclehire://map/"] saveAppState];
}
@end

