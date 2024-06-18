//
//  CHViewCentering.m
//  Chalk
//
//  Created by Pierre Chatelier on 28/04/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHViewCentering.h"

#import "NSViewExtended.h"

@implementation CHViewCentering

@synthesize centerHorizontally;
@synthesize centerVertically;

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self->localObserver];
  [self->localObserver release];
  [super dealloc];
}
//end dealloc

-(void) viewWillMoveToSuperview:(NSView*)superview
{
  [[NSNotificationCenter defaultCenter] removeObserver:self->localObserver name:NSViewFrameDidChangeNotification object:self.superview];
  [self->localObserver release];
  self->localObserver = nil;
  __block __weak NSView* newSuperview = superview;
  __block __weak CHViewCentering* selfView = self;
  self->localObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSViewFrameDidChangeNotification object:newSuperview queue:nil usingBlock:^(NSNotification* note) {
     [selfView centerInParentHorizontally:selfView.centerHorizontally vertically:selfView.centerVertically];
  }];
  [self->localObserver retain];
}
//end viewDidMoveToSuperview

@end
