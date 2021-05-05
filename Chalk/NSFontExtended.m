//
//  NSFontExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 15/03/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSFontExtended.h"

@implementation NSFont (Extended)
-(NSFont*) boldFont
{
  NSFont* result = [[NSFontManager sharedFontManager] convertFont:self toHaveTrait:NSBoldFontMask];
  return result;
}
//end boldFont

-(NSFont*) italicFont
{
  NSFont* result = [[NSFontManager sharedFontManager] convertFont:self toHaveTrait:NSItalicFontMask];
  return result;
}
//end italicFont


@end
