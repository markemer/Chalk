//
//  CHStepper.h
//  Chalk
//
//  Created by Pierre Chatelier on 20/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol CHStepperDelegate;
@class CHStepperAssistant;

@interface CHStepper : NSControl {
  NSStepper* innerStepper;
  CHStepperAssistant* assistant;
}

@property NSControlSize controlSize;
@property(assign) id<CHStepperDelegate> delegate;

@end

@protocol CHStepperDelegate
@required
-(BOOL) stepperShouldIncrement:(CHStepper*)stepper;
-(BOOL) stepperShouldDecrement:(CHStepper*)stepper;
@end
