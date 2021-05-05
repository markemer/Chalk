//
//  JSDictionary.m
//  Chalk
//
//  Created by Pierre Chatelier on 06/02/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "JSDictionary.h"

@implementation JSDictionary

@synthesize dictionary;

+(BOOL) isSelectorExcludedFromWebScript:(SEL)sel
{
  BOOL result = YES;
  BOOL included =
    (sel == @selector(objectForKey:));
  result = !included;
  return result;
}
//end isSelectorExcludedFromWebScript:

+(instancetype) jsDictionary
{
  return [[[[self class] alloc] init] autorelease];
}
//end jsDictionary

+(instancetype) jsDictionaryWithDictionary:(NSDictionary*)aDictionary
{
  return [[[[self class] alloc] initWithDictionary:aDictionary] autorelease];
}
//end jsDictionaryWithDictionary:

-(instancetype) init
{
  return [self initWithDictionary:@{}];
}
//end init:

-(instancetype) initWithDictionary:(NSDictionary*)aDictionary
{
  if (!((self = [super init])))
    return nil;
  self->dictionary = [aDictionary retain];
  return self;
}
//end initWithDictionary:

-(void) dealloc
{
  [self->dictionary release];
  [super dealloc];
}
//end dealloc

-(id) objectForKey:(id)key
{
  return [self->dictionary objectForKey:key];
}
//end objectForKey:

@end
