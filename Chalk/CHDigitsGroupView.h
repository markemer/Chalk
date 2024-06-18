//
//  CHDigitsGroupView.h
//  Chalk
//
//  Created by Pierre Chatelier on 25/03/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHChalkUtils.h"

@class CHDigitsGroupNavigatorView;

@interface CHDigitsGroupView : NSView {
  NSMutableArray* digitViews;
  NSMutableArray* hintViews;
  NSUInteger rowsCount;
  NSUInteger digitsGroupIndex;
  BOOL presentationIsDirty;
}

@property(nonatomic,assign) IBOutlet CHDigitsGroupNavigatorView* navigatorView;
@property(nonatomic) NSUInteger digitsGroupIndex;

@property(assign) id delegate;

-(void) invalidatePresentation;
-(void) updateControls;

@end
