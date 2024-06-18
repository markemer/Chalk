//
//  CHStepperNumber.h
//  Chalk
//
//  Created by Pierre Chatelier on 04/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHStepper.h"

@interface CHStepperNumber : CHStepper {
  NSNumber* minValue;
  NSNumber* maxValue;
  NSNumber* increment;
  NSNumber* _value;
}

@property(copy) NSNumber* minValue;
@property(copy) NSNumber* maxValue;
@property(copy) NSNumber* increment;
@property(copy) NSNumber* value;
@property(copy) NSString* stringValue;
@property(copy) NSAttributedString* attributedStringValue;
@property(copy) id objectValue;
@property int intValue;
@property NSInteger integerValue;
@property float floatValue;
@property double doubleValue;
@property BOOL autorepeat;
@property BOOL valueWraps;

-(void)takeIntValueFrom:(id)sender;
-(void)takeFloatValueFrom:(id)sender;
-(void)takeDoubleValueFrom:(id)sender;
-(void)takeStringValueFrom:(id)sender;
-(void)takeObjectValueFrom:(id)sender;
-(void)takeIntegerValueFrom:(id)sender;

@end
