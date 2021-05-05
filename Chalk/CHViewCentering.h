//
//  CHViewCentering.h
//  Chalk
//
//  Created by Pierre Chatelier on 28/04/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CHViewCentering : NSView {
  id localObserver;
}

@property(nonatomic) BOOL centerHorizontally;
@property(nonatomic) BOOL centerVertically;

@end
