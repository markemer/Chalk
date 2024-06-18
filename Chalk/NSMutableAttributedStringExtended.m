//
//  NSMutableAttributedStringExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 23/10/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "NSMutableAttributedStringExtended.h"

@implementation NSMutableAttributedString (Extended)

-(BOOL) appendCharacter:(char)character count:(NSUInteger)count
{
  BOOL result = NO;
  NSUInteger allocationSize = count*sizeof(character);
  char* buffer = (count <= 1) ? 0 : malloc(allocationSize);
  while(!buffer && (allocationSize>1))
  {
    allocationSize /= 2;
    buffer = malloc(allocationSize);
  }//end while(!buffer && (allocationSize>1))
  if (!buffer)
  {
    NSString* string = [[NSString alloc] initWithBytes:&character length:sizeof(character) encoding:NSUTF8StringEncoding];
    NSAttributedString* attributedString = !string ? nil : [[NSAttributedString alloc] initWithString:string];
    result = (attributedString != nil);
    if (attributedString)
      for(NSUInteger i = 0 ; i<count ; ++i)
        [self appendAttributedString:attributedString];
    [attributedString release];
    [string release];
  }//end if (!buffer)
  else//if (buffer)
  {
    memset(buffer, character, allocationSize);
    NSString* string = [[NSString alloc] initWithBytesNoCopy:buffer length:allocationSize encoding:NSUTF8StringEncoding freeWhenDone:NO];
    NSAttributedString* attributedString = !string ? nil : [[NSAttributedString alloc] initWithString:string];
    result = (attributedString != nil);
    NSUInteger nbFullBuffers = count/allocationSize;
    if (string)
      for(NSUInteger i = 0 ; i<nbFullBuffers ; ++i)
        [self appendAttributedString:attributedString];
    NSUInteger remainingPart = count%allocationSize;
    if (remainingPart)
      [self appendAttributedString:[attributedString attributedSubstringFromRange:NSMakeRange(0, remainingPart)]];
    [attributedString release];
    [string release];
    free(buffer);
  }//end if (buffer)
  return result;
}
//end appendCharacter:count:

@end
