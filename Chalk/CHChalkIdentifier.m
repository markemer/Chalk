//
//  CHChalkIdentifier.m
//  Chalk
//
//  Created by Pierre Chatelier on 14/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkIdentifier.h"

#import "CHChalkIdentifierConstant.h"
#import "CHChalkUtils.h"

@implementation CHChalkIdentifier

@synthesize caseSensitive;
@synthesize name;
@synthesize tokens;
@synthesize symbol;
@synthesize symbolAsText;
@synthesize symbolAsTeX;

#pragma mark constants

+(BOOL) supportsSecureCoding {return YES;}

+(instancetype) ppmIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"ppm" caseSensitive:NO tokens:@[@"ppm"] symbol:@"ppm" symbolAsText:@"ppm" symbolAsTeX:@"ppm"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end ppmIdentifier

+(instancetype) noIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"no" caseSensitive:NO tokens:@[@"no",@"false"] symbol:@"no" symbolAsText:@"no" symbolAsTeX:@"no"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end noIdentifier

+(instancetype) unlikelyIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"unlikely" caseSensitive:NO tokens:@[@"unlikely"] symbol:@"unlikely" symbolAsText:@"unlikely" symbolAsTeX:@"unlikely"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end unlikelyIdentifier

+(instancetype) maybeIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"maybe" caseSensitive:NO tokens:@[@"maybe"] symbol:@"maybe" symbolAsText:@"maybe" symbolAsTeX:@"maybe"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end maybeIdentifier

+(instancetype) certainlyIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"certainly" caseSensitive:NO tokens:@[@"certainly"] symbol:@"certainly" symbolAsText:@"certainly" symbolAsTeX:@"certainly"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end certainlyIdentifier

+(instancetype) yesIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"yes" caseSensitive:NO tokens:@[@"true",@"yes"] symbol:@"yes" symbolAsText:@"yes" symbolAsTeX:@"yes"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end yesIdentifier

+(instancetype) nanIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"nan" caseSensitive:NO tokens:@[@"nan"] symbol:@"NaN" symbolAsText:@"NaN" symbolAsTeX:@"NaN"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end nanIdentifier

+(instancetype) infinityIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"infinity" caseSensitive:NO tokens:@[@"inf",@"infinity",NSSTRING_INFINITY] symbol:NSSTRING_INFINITY symbolAsText:NSSTRING_INFINITY symbolAsTeX:@"\\infty{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end infinityIdentifier

+(instancetype) piIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"pi" caseSensitive:NO tokens:@[@"PI",NSSTRING_PI,@"\u03C0",@"\u1D6D1",@"\u1D70B",@"\u1D745",@"\u1D77F",@"\u1D7B9"] symbol:NSSTRING_PI symbolAsText:@"pi" symbolAsTeX:@"\\pi{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end piIdentifier

+(instancetype) eIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"e" caseSensitive:NO tokens:@[@"E"] symbol:@"e" symbolAsText:@"e" symbolAsTeX:@"e{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end eIdentifier

+(instancetype) iIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"i" caseSensitive:YES tokens:@[@"i"] symbol:@"i" symbolAsText:@"i" symbolAsTeX:@"i{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end iIdentifier

+(instancetype) jIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"j" caseSensitive:YES tokens:@[@"j"] symbol:@"j" symbolAsText:@"j" symbolAsTeX:@"j{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end jIdentifier

+(instancetype) kIdentifier
{
  static CHChalkIdentifier* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[CHChalkIdentifierConstant alloc] initWithName:@"k" caseSensitive:YES tokens:@[@"k"] symbol:@"k" symbolAsText:@"k" symbolAsTeX:@"k{}"];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end kIdentifier

#pragma mark custom

-(instancetype) initWithName:(NSString*)aName caseSensitive:(BOOL)aCaseSensitive tokens:(NSArray*)aTokens symbol:(NSString*)aSymbol symbolAsText:(NSString*)aSymbolAsText symbolAsTeX:(NSString*)aSymbolAsTeX
{
  if (!((self = [super init])))
    return nil;
  self->caseSensitive = aCaseSensitive;
  self->name = [aName copy];
  self->tokens = [aTokens copy];
  self->symbol = [aSymbol copy];
  self->symbolAsText = [aSymbolAsText copy];
  self->symbolAsTeX = [aSymbolAsTeX copy];
  return self;
}
//end initWithName:caseSensitive:tokens:symbol:symbolAstext:symbolAsTeX:

-(void) dealloc
{
  [self->name release];
  [self->tokens release];
  [self->symbol release];
  [self->symbolAsText release];
  [self->symbolAsTeX release];
  [super dealloc];
}
//end dealloc

-(id) initWithCoder:(NSCoder*)aDecoder
{
  NSString* aName = (NSString*)[aDecoder decodeObjectOfClass:[NSString class] forKey:@"name"];
  BOOL aCaseSensitive = [aDecoder decodeBoolForKey:@"caseSensitive"];
  NSArray* aTokens = (NSArray*)[aDecoder decodeObjectOfClass:[NSArray class] forKey:@"tokens"];
  NSString* aSymbol = (NSString*)[aDecoder decodeObjectOfClass:[NSString class] forKey:@"symbol"];
  NSString* aSymbolAsText = (NSString*)[aDecoder decodeObjectOfClass:[NSString class] forKey:@"symbolAsText"];
  NSString* aSymbolAsTeX = (NSString*)[aDecoder decodeObjectOfClass:[NSString class] forKey:@"symbolAsTeX"];
  return [self initWithName:aName caseSensitive:aCaseSensitive tokens:aTokens symbol:aSymbol symbolAsText:aSymbolAsText symbolAsTeX:aSymbolAsTeX];
}
//end initWithCoder:

-(void) encodeWithCoder:(NSCoder*)aCoder
{
  [aCoder encodeObject:self->name forKey:@"name"];
  [aCoder encodeBool:self->caseSensitive forKey:@"caseSensitive"];
  [aCoder encodeObject:self->tokens forKey:@"tokens"];
  [aCoder encodeObject:self->symbol forKey:@"symbol"];
  [aCoder encodeObject:self->symbolAsText forKey:@"symbolAsText"];
  [aCoder encodeObject:self->symbolAsTeX forKey:@"symbolAsTeX"];
}
//end encodeWithCoder:

-(id) copyWithZone:(NSZone*)zone
{
  CHChalkIdentifier* result = [[[self class] allocWithZone:zone] initWithName:self->name caseSensitive:self->caseSensitive tokens:self->tokens symbol:self->symbol symbolAsText:self->symbolAsText symbolAsTeX:self->symbolAsTeX];
  return result;
}
//end copyWithZone:

-(BOOL) matchesName:(NSString*)aName
{
  BOOL result = ([self->name compare:aName options:!self->caseSensitive ? NSCaseInsensitiveSearch : 0] == NSOrderedSame);
  return result;
}
//end matchesName:

-(BOOL) matchesToken:(NSString*)token
{
  __block BOOL result = NO;
  [self->tokens enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    BOOL isMatching = ([obj compare:token options:!self->caseSensitive ? NSCaseInsensitiveSearch : 0] == NSOrderedSame);
    if (isMatching)
      result = true;
    *stop |= result;
  }];
  return result;
}
//end matchesToken:

@end
