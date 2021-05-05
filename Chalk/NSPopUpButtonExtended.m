//
//  NSPopUpButtonExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 22/05/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSPopUpButtonExtended.h"

@implementation NSPopUpButton (Extended)

-(BOOL) selectItemWithTag:(NSInteger)tag emptySelectionOnFailure:(BOOL)emptySelectionOnFailure
{
  BOOL result = [self selectItemWithTag:tag];
  if (!result)
  {
    [self selectItem:nil];
    result = YES;
  }//end if (!result)
  return result;
}
//end selectItemWithTag:emptySelectionOnFailure:

@end
