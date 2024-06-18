//
//  NSPopUpButtonExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 22/05/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSPopUpButton (Extended)

-(BOOL) selectItemWithTag:(NSInteger)tag emptySelectionOnFailure:(BOOL)emptySelectionOnFailure;

@end
