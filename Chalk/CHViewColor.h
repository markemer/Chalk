//
//  CHViewColor.h
//  Chalk
//
//  Created by Pierre Chatelier on 20/05/2017.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CHViewColor : NSView {
  NSColor* backgroundColor;
}

@property(nonatomic,copy) NSColor* backgroundColor;

@end
