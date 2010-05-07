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

- (TTStyle*)testBtn {

		return 
		[TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
		 [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
		  [TTShadowStyle styleWithColor:RGBACOLOR(255,255,255,0) blur:1 offset:CGSizeMake(0, 1) next:
		   [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(255, 255, 255)
											   color2:RGBCOLOR(216, 221, 231) next:
			[TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
			 [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
			  [TTTextStyle styleWithFont:nil color:TTSTYLEVAR(linkTextColor)
							 shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
							shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
}
@end
