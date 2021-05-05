//
//  CHProgressIndicator.h
//  Chalk
//
//  Created by Pierre Chatelier on 31/10/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CHProgressIndicator : NSProgressIndicator {
  BOOL animationStarted;
}

@property BOOL animated;

@end
