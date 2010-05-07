//
//  AttractionListViewController.h
//  CycleHire
//
//  Created by Alexander Baxevanis on 28/03/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "Three20/Three20.h"

@interface AttractionListViewController : TTTableViewController <MFMailComposeViewControllerDelegate> {
	
}

- (id)initWithTitle: (NSString *) title attractionsCSV: (NSString *) csvFileName;

@end
