//
//  CHDigitView.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/04/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHChalkUtils.h"

@interface CHDigitView : NSTextField

@property(nonatomic,assign) id clickDelegate;
@property(nonatomic,copy) NSArray* backColors1;
@property(nonatomic,copy) NSArray* backColors2;

@property(nonatomic) NSUInteger digitIndexNatural;
@property(nonatomic) NSUInteger digitIndexVisual;
@property(nonatomic) chalk_number_part_minor_type_t digitMinorPart;

-(void) viewDidClick:(id)sender;

@end
