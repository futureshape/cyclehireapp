//
//  GlobalStyleSheet.m
//  CycleHire
//
//  Created by Alexander Baxevanis on 03/04/2010.
//  Copyright 2010 Alexander Baxevanis. All rights reserved.
//

#import "GlobalStyleSheet.h"


@implementation GlobalStyleSheet

- (TTStyle*) redText {
	return [TTTextStyle styleWithColor:[UIColor redColor] next:nil];
}

- (TTStyle*) locationText {
	return [TTTextStyle styleWithFont:[UIFont boldSystemFontOfSize:14]
								color:[UIColor blackColor]
						textAlignment:UITextAlignmentCenter 
								 next:nil];
}

@end
