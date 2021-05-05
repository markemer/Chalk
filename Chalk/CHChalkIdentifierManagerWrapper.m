//
//  CHChalkIdentifierManagerWrapper.m
//  Chalk
//
//  Created by Pierre Chatelier on 18/05/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkIdentifierManagerWrapper.h"

@implementation CHChalkIdentifierManagerWrapper

-(instancetype) initSharing:(CHChalkIdentifierManager*)other
{
  if (!((self = [super initSharing:other])))
    return nil;
  self->identifierDynamicValues = [[NSMapTable alloc] initWithKeyOptions:NSMapTableObjectPointerPersonality valueOptions:NSMapTableObjectPointerPersonality capacity:0];
  return self;
}
//end initSharing:

-(void) dealloc
{
  [self->identifierDynamicValues release];
  [super dealloc];
}
//end dealloc

-(CHChalkValue*) valueForIdentifier:(CHChalkIdentifier*)identifier
{
  CHChalkValue* result = nil;
  if (identifier)
  {
    @synchronized(self)
    {
      result = [self->identifierDynamicValues objectForKey:identifier];
    }//end @synchronized(self)
   if (!result)
      result = [super valueForIdentifier:identifier];
  }//end if (identifier)
  return result;
}
//end valueForIdentifier:

-(BOOL) setValue:(CHChalkValue*)value forIdentifier:(CHChalkIdentifier*)identifier
{
  BOOL result = NO;
  if (identifier)
  {
    @synchronized(self)
    {
      if (value)
        [self->identifierDynamicValues setObject:value forKey:identifier];
      else
        [self->identifierDynamicValues removeObjectForKey:identifier];
    }//end @synchronized(self)
  }//end if (identifier)
  return result;
}
//end setValue:forIdentifier:

-(void) resetDynamicIdentifierValues
{
  @synchronized(self)
  {
    [self->identifierDynamicValues removeAllObjects];
  }//end @synchronized(self)
}
//end resetDynamicIdentifierValues

@end
