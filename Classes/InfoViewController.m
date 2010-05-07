//
//  InfoViewController.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 06/05/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "InfoViewController.h"


@implementation InfoViewController

-(id) init {
	if (self = [super init]) {
		self.tableViewStyle = UITableViewStyleGrouped;
		self.title = NSLocalizedString(@"About", nil);
		
		self.dataSource = [TTSectionedDataSource dataSourceWithObjects:@"",
						   [TTTableTextItem itemWithText:NSLocalizedString(@"Acknowledgements", nil) URL:@"bundle://acknowledgements.html"],
						   [TTTableTextItem itemWithText:NSLocalizedString(@"Feedback", nil) URL:@""],
						   nil];
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = NO;
}

@end
