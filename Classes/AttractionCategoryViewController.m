//
//  AttractionCategoryViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 27/03/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "AttractionCategoryViewController.h"
#import "AttractionListViewController.h"

@implementation AttractionCategoryViewController

- (id)init {
	if (self = [super init]) {
		self.title = NSLocalizedString(@"Attractions", nil);
		self.variableHeightRows = YES;
		
		self.dataSource = [TTListDataSource dataSourceWithObjects:
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Famous areas & landmarks", nil)
												 imageURL:@"bundle://landmarks.png"
													  URL:[@"cyclehire://attractions/category/Famous areas & landmarks/attractions-landmarks.csv"
														   stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]],
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Museums", nil)
												 imageURL:@"bundle://landmarks.png"
													  URL:@"cyclehire://attractions/category/Museums/attractions-museums.csv"],
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Art Galleries", nil) 
												 imageURL:@"bundle://landmarks.png"
													  URL:[@"cyclehire://attractions/category/Art Galleries/attractions-galleries.csv"	
															stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]],
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Fun & leisure", nil) 
												 imageURL:@"bundle://landmarks.png"
													  URL:[@"cyclehire://attractions/category/Fun & Leisure/attractions-fun.csv" 
															stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]],
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Churches", nil) 
												 imageURL:@"bundle://landmarks.png"
													  URL:@"cyclehire://attractions/category/Churches/attractions-churches.csv"],
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Music", nil) 
												 imageURL:@"bundle://landmarks.png"
													  URL:@"cyclehire://attractions/category/Music/attractions-music.csv"],
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Cinema", nil) 
												 imageURL:@"bundle://landmarks.png"
													  URL:@"cyclehire://attractions/category/Cinema/attractions-cinema.csv"],
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Theatre", nil) 
												 imageURL:@"bundle://landmarks.png"
													  URL:@"cyclehire://attractions/category/Theatre/attractions-theatre.csv"],
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Shopping & Markets", nil) 
												 imageURL:@"bundle://landmarks.png"
													  URL:[@"cyclehire://attractions/category/Shopping & Markets/attractions-shopping.csv"
															stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]],
						   [TTTableImageItem itemWithText:NSLocalizedString(@"Parks", nil) 
												 imageURL:@"bundle://landmarks.png"
													  URL:@"cyclehire://attractions/category/Parks/attractions-parks.csv"],
						   nil];
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;
}

- (void)dealloc {
    [super dealloc];
}


@end
