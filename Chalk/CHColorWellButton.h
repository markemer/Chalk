//
//  CHColorWellButton.h
//  Chalk
//
//  Created by Pierre Chatelier on 31/10/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CHColorWellButton;

@protocol CHColorWellButtonDelegate
-(IBAction) changeColor:(id)sender;
@end

@interface CHColorWellButton : NSButton

@property(assign) IBOutlet NSColorWell* associatedColorWell;
@property(assign) id<CHColorWellButtonDelegate> delegate;

-(IBAction) click:(id)sender;

@end
