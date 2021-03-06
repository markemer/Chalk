//
//  CHEquationTextView.h
//  Chalk
//
//  Created by Pierre Chatelier on 04/05/2017.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHChalkTypes.h"

@interface CHEquationTextView : NSTextView <NSDraggingDestination>

@property(assign) id<CHPasteboardDelegate> pasteboardDelegate;

@end
