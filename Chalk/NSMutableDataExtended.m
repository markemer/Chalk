//
//  NSMutableDataExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 23/10/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSMutableDataExtended.h"

@implementation NSMutableData (Extended)

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
    for(NSUInteger i = 0 ; i<count ; ++i)
      [self appendBytes:&character length:sizeof(character)];
    result = YES;
  }//end if (!buffer)
  else//if (buffer)
  {
    memset(buffer, character, allocationSize);
    NSUInteger nbFullBuffers = count/allocationSize;
    for(NSUInteger i = 0 ; i<nbFullBuffers ; ++i)
      [self appendBytes:buffer length:allocationSize];
    NSUInteger remainingPart = count%allocationSize;
    if (remainingPart)
      [self appendBytes:buffer length:remainingPart];
    result = YES;
    free(buffer);
  }//end if (buffer)
  return result;
}
//end appendCharacter:count:

@end
