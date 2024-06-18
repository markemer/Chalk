//
//  CHChalkIdentifierManager.m
//  Chalk
//
//  Created by Pierre Chatelier on 06/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkIdentifierManager.h"

#import "CHChalkIdentifier.h"
#import "CHChalkIdentifierConstant.h"
#import "CHChalkIdentifierFunction.h"
#import "CHChalkIdentifierVariable.h"
#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHChalkIdentifierManager

@dynamic constantsIdentifiers;
@dynamic variablesIdentifiers;

+(NSArray*) defaultIdentifiers
{
  static NSArray* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [[[[[NSArray array]
           arrayByAddingObjectsFromArray:[self defaultIdentifiersSymbols]]
           arrayByAddingObjectsFromArray:[self defaultIdentifiersConstants]]
           arrayByAddingObjectsFromArray:[self defaultIdentifiersFunctions]]
           retain];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end defaultIdentifiers

+(NSArray*) defaultIdentifiersSymbols
{
  static NSArray* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [@[[CHChalkIdentifier ppmIdentifier]
                     ] retain];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end defaultIdentifiersSymbols

+(NSArray*) defaultIdentifiersConstants
{
  static NSArray* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [@[[CHChalkIdentifier noIdentifier],
                      [CHChalkIdentifier unlikelyIdentifier],
                      [CHChalkIdentifier maybeIdentifier],
                      [CHChalkIdentifier certainlyIdentifier],
                      [CHChalkIdentifier yesIdentifier],
                      [CHChalkIdentifier nanIdentifier],
                      [CHChalkIdentifier infinityIdentifier],
                      [CHChalkIdentifier piIdentifier],
                      [CHChalkIdentifier eIdentifier],
                      [CHChalkIdentifier iIdentifier],
                      [CHChalkIdentifier jIdentifier],
                      [CHChalkIdentifier kIdentifier]
                     ] retain];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end defaultIdentifiersConstants

+(NSArray*) defaultIdentifiersFunctions
{
  static NSArray* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      if (!instance)
        instance = [@[[CHChalkIdentifierFunction intervalIdentifier],
                      [CHChalkIdentifierFunction absIdentifier],
                      [CHChalkIdentifierFunction angleIdentifier], [CHChalkIdentifierFunction anglesIdentifier],
                      [CHChalkIdentifierFunction floorIdentifier], [CHChalkIdentifierFunction ceilIdentifier],
                      [CHChalkIdentifierFunction invIdentifier],
                      [CHChalkIdentifierFunction powIdentifier], [CHChalkIdentifierFunction rootIdentifier], [CHChalkIdentifierFunction sqrtIdentifier], [CHChalkIdentifierFunction cbrtIdentifier],
                      [CHChalkIdentifierFunction expIdentifier],
                      [CHChalkIdentifierFunction lnIdentifier], [CHChalkIdentifierFunction log10Identifier],
                      [CHChalkIdentifierFunction sinIdentifier], [CHChalkIdentifierFunction cosIdentifier], [CHChalkIdentifierFunction tanIdentifier],
                      [CHChalkIdentifierFunction asinIdentifier], [CHChalkIdentifierFunction acosIdentifier], [CHChalkIdentifierFunction atanIdentifier], [CHChalkIdentifierFunction atan2Identifier],
                      [CHChalkIdentifierFunction sinhIdentifier], [CHChalkIdentifierFunction coshIdentifier], [CHChalkIdentifierFunction tanhIdentifier],
                      [CHChalkIdentifierFunction asinhIdentifier], [CHChalkIdentifierFunction acoshIdentifier], [CHChalkIdentifierFunction atanhIdentifier],
                      [CHChalkIdentifierFunction gammaIdentifier],
                      [CHChalkIdentifierFunction zetaIdentifier],
                      [CHChalkIdentifierFunction conjIdentifier],
                      [CHChalkIdentifierFunction matrixIdentifier], [CHChalkIdentifierFunction identityIdentifier],
                      [CHChalkIdentifierFunction transposeIdentifier],
                      [CHChalkIdentifierFunction traceIdentifier], [CHChalkIdentifierFunction detIdentifier],
                      [CHChalkIdentifierFunction isPrimeIdentifier],
                      [CHChalkIdentifierFunction nextPrimeIdentifier],
                      [CHChalkIdentifierFunction nthPrimeIdentifier],
                      [CHChalkIdentifierFunction primesIdentifier],
                      [CHChalkIdentifierFunction gcdIdentifier], [CHChalkIdentifierFunction lcmIdentifier],
                      [CHChalkIdentifierFunction modIdentifier],
                      [CHChalkIdentifierFunction binomialIdentifier], [CHChalkIdentifierFunction primorialIdentifier],
                      [CHChalkIdentifierFunction fibonacciIdentifier], [CHChalkIdentifierFunction jacobiIdentifier],
                      [CHChalkIdentifierFunction inputIdentifier],
                      [CHChalkIdentifierFunction outputIdentifier], [CHChalkIdentifierFunction output2Identifier],
                      [CHChalkIdentifierFunction fromBaseIdentifier],
                      [CHChalkIdentifierFunction inFileIdentifier], [CHChalkIdentifierFunction outFileIdentifier],
                      [CHChalkIdentifierFunction toU8Identifier], [CHChalkIdentifierFunction toS8Identifier],
                      [CHChalkIdentifierFunction toU16Identifier], [CHChalkIdentifierFunction toS16Identifier],
                      [CHChalkIdentifierFunction toU32Identifier], [CHChalkIdentifierFunction toS32Identifier],
                      [CHChalkIdentifierFunction toU64Identifier], [CHChalkIdentifierFunction toS64Identifier],
                      [CHChalkIdentifierFunction toU128Identifier], [CHChalkIdentifierFunction toS128Identifier],
                      [CHChalkIdentifierFunction toU256Identifier], [CHChalkIdentifierFunction toS256Identifier],
                      [CHChalkIdentifierFunction toUCustomIdentifier], [CHChalkIdentifierFunction toSCustomIdentifier],
                      [CHChalkIdentifierFunction toChalkIntegerIdentifier],
                      [CHChalkIdentifierFunction toF16Identifier],
                      [CHChalkIdentifierFunction toF32Identifier],
                      [CHChalkIdentifierFunction toF64Identifier],
                      [CHChalkIdentifierFunction toF128Identifier],
                      [CHChalkIdentifierFunction toF256Identifier],
                      [CHChalkIdentifierFunction toChalkFloatIdentifier],
                      [CHChalkIdentifierFunction fromU8Identifier], [CHChalkIdentifierFunction fromS8Identifier],
                      [CHChalkIdentifierFunction fromU16Identifier], [CHChalkIdentifierFunction fromS16Identifier],
                      [CHChalkIdentifierFunction fromU32Identifier], [CHChalkIdentifierFunction fromS32Identifier],
                      [CHChalkIdentifierFunction fromU64Identifier], [CHChalkIdentifierFunction fromS64Identifier],
                      [CHChalkIdentifierFunction fromU128Identifier], [CHChalkIdentifierFunction fromS128Identifier],
                      [CHChalkIdentifierFunction fromUCustomIdentifier], [CHChalkIdentifierFunction fromSCustomIdentifier],
                      [CHChalkIdentifierFunction fromChalkIntegerIdentifier],
                      [CHChalkIdentifierFunction fromF16Identifier],
                      [CHChalkIdentifierFunction fromF32Identifier],
                      [CHChalkIdentifierFunction fromF64Identifier],
                      [CHChalkIdentifierFunction fromF128Identifier],
                      [CHChalkIdentifierFunction fromChalkFloatIdentifier],
                      [CHChalkIdentifierFunction shiftIdentifier],
                      [CHChalkIdentifierFunction rollIdentifier],
                      [CHChalkIdentifierFunction bitsSwapIdentifier],
                      [CHChalkIdentifierFunction bitsReverseIdentifier],
                      [CHChalkIdentifierFunction bitsConcatLEIdentifier],
                      [CHChalkIdentifierFunction bitsConcatBEIdentifier],
                      [CHChalkIdentifierFunction golombRiceDecodeIdentifier],
                      [CHChalkIdentifierFunction golombRiceEncodeIdentifier],
                      [CHChalkIdentifierFunction hConcatIdentifier],
                      [CHChalkIdentifierFunction vConcatIdentifier],
                      [CHChalkIdentifierFunction sumIdentifier],
                      [CHChalkIdentifierFunction productIdentifier],
                      [CHChalkIdentifierFunction integralIdentifier]
                     ] retain];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end defaultIdentifiersFunctions

+(instancetype) identifierManagerWithDefaults:(BOOL)withDefaults
{
  CHChalkIdentifierManager* result = [[[CHChalkIdentifierManager alloc] init] autorelease];
  if (withDefaults)
  {
    for(CHChalkIdentifier* defaultIdentifier in [self defaultIdentifiers])
      [result addIdentifier:defaultIdentifier replace:YES preventTokenConflict:YES];
  }//end if (withDefaults)
  return result;
}
//end identifierManagerWithDefaults:

-(instancetype) init
{
  return [self initSharing:nil];
}
//end init

-(instancetype) initSharing:(CHChalkIdentifierManager*)other
{
  if (!((self = [super init])))
    return nil;
  self->identifiersByName = other ? [other->identifiersByName retain] : [[NSMutableDictionary alloc] init];
  self->identifierValues = other ? [other->identifierValues retain] : [[NSMapTable alloc] initWithKeyOptions:NSMapTableObjectPointerPersonality valueOptions:NSMapTableObjectPointerPersonality capacity:0];
  return self;
}
//end initSharing:

-(void) dealloc
{
  [self->identifiersByName release];
  [self->identifierValues release];
  [super dealloc];
}
//end dealloc

-(instancetype) copyWithZone:(NSZone*)zone
{
  CHChalkIdentifierManager* result = [[CHChalkIdentifierManager alloc] init];
  if (result)
  {
    [result->identifiersByName release];
    result->identifiersByName = [self->identifiersByName mutableCopyWithZone:zone];
    [result->identifierValues release];
    result->identifierValues = [self->identifierValues copyWithZone:zone];
  }//end if (result)
  return result;
}
//end copyWithZone:

-(NSArray*) constantsIdentifiers
{
  NSArray* result = [[self->identifiersByName allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    BOOL result = [evaluatedObject isKindOfClass:[CHChalkIdentifierConstant class]];
    return result;
  }]];
  return result;
}
//end constantsIdentifiers

-(NSArray*) variablesIdentifiers
{
  NSArray* result = [[self->identifiersByName allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    BOOL result = [evaluatedObject isKindOfClass:[CHChalkIdentifierVariable class]];
    return result;
  }]];
  return result;
}
//end variablesIdentifiers

-(NSString*) unusedIdentifierNameWithTokenOption:(BOOL)tokenOption
{
  NSString* result = nil;
  static const char letters[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  @synchronized(self)
  {
    NSUInteger count = 1;
    BOOL stop = NO;
    while(!stop)
    {
      for(NSUInteger index = 0 ; !stop && (index<sizeof(letters)-1) ; ++index)
      {
        NSMutableString* string = [NSMutableString stringWithCapacity:count];
        stop |= !string;
        for(NSUInteger i = 0 ; i<count ; ++i)
          [string appendFormat:@"%c", letters[index]];
        BOOL unusedName = ![self identifierForName:string createClass:Nil];
        if (unusedName)
        {
          BOOL unusedToken = !tokenOption || ![self isUsedIdentifierToken:string];
          if (unusedToken)
            result = [[string copy] autorelease];
        }//end if (unused)
        stop |= (result != nil);
      }//end or each index
      ++count;
    }//end while(!stop)
  }//end @synchronized
  return result;
}
//end unusedIdentifierNameWithTokenOption:

-(NSString*) unusedIdentifierNameWithName:(NSString*)name
{
  NSString* result = nil;
  @synchronized(self)
  {
    NSString* currentName = [[name copy] autorelease];
    if (![NSString isNilOrEmpty:currentName])
    {
      NSUInteger count = 1;
      BOOL stop = NO;
      while(!stop)
      {
        BOOL isAlreadyUsed = [self hasIdentifierName:currentName];
        stop |= !isAlreadyUsed;
        if (isAlreadyUsed)
          currentName = [NSString stringWithFormat:@"%@_%@", name, @(++count)];
        stop |= !currentName;
      }//end or each index
      result = [[currentName copy] autorelease];
    }//end if (![NSString isNilOrEmpty:currentName])
  }//end @synchronized
  return result;
}
//end unusedIdentifierNameWithName:

-(BOOL) addIdentifier:(CHChalkIdentifier*)identifier replace:(BOOL)replace preventTokenConflict:(BOOL)preventTokenConflict
{
  BOOL result = NO;
  NSString* key = identifier.name;
  if (key)
  {
    @synchronized(self)
    {
      CHChalkIdentifier* existingIdentifier = [self->identifiersByName objectForKey:key];
      if (existingIdentifier == identifier)
        result = YES;
      else if (!existingIdentifier || replace)
      {
        __block BOOL tokenConflict = NO;
        if (preventTokenConflict)
        {
          NSSet* tokens = [NSSet setWithArray:identifier.tokens];
          [self->identifiersByName enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            CHChalkIdentifier* other = [obj dynamicCastToClass:[CHChalkIdentifier class]];
            tokenConflict |= other && [tokens intersectsSet:[NSSet setWithArray:other.tokens]];
            *stop |= tokenConflict;
          }];
        }//end if (preventTokenConflict)
        if (!tokenConflict)
        {
          [self->identifiersByName setObject:identifier forKey:key];
          result = YES;
        }//end if (!tokenConflict)
      }//end if (!existingIdentifier || replace)
    }//end @synchronized(self)
  }//end if (key)
  return result;
}
//end addIdentifier:

-(BOOL) removeIdentifier:(CHChalkIdentifier*)identifier
{
  BOOL result = NO;
  NSString* key = identifier.name;
  if (key)
  {
    @synchronized(self)
    {
      BOOL hasObject = ([self->identifiersByName objectForKey:key] != nil);
      [self->identifiersByName removeObjectForKey:key];
      [self->identifierValues removeObjectForKey:identifier];
      result = hasObject;
    }//end @synchronized(self)
  }//end if (key)
  return result;
}
//end removeIdentifier:

-(void) removeAllExceptDefaults:(BOOL)exceptDefault
{
  @synchronized(self)
  {
    if (!exceptDefault)
    {
      [self->identifiersByName removeAllObjects];
      [self->identifierValues removeAllObjects];
    }//end if (!exceptDefault)
    else//if (exceptDefault)
    {
      NSSet* identifiersToRemove = nil;
      NSSet* defaultIdentifiers = [NSSet setWithArray:[[self class] defaultIdentifiers]];
      identifiersToRemove = [self->identifiersByName keysOfEntriesWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id key, id obj, BOOL *stop) {
        return ![defaultIdentifiers containsObject:obj];
      }];
      for(CHChalkIdentifier* identifierToRemove in identifiersToRemove)
        [self removeIdentifier:identifierToRemove];
    }//end if (exceptDefault)
  }//end @synchronized(self)
}
//end removeAllExceptDefaults

-(BOOL) hasIdentifier:(CHChalkIdentifier*)identifier
{
  BOOL result = [self hasIdentifierName:identifier.name];
  return result;
}
//end hasIdentifier:

-(BOOL) hasIdentifierName:(NSString*)name
{
  BOOL result = NO;
  NSString* key = name;
  if (key)
  {
    @synchronized(self)
    {
      result = ([self->identifiersByName objectForKey:key] != nil);
    }//end @synchronized(self)
  }//end if (key)
  return result;
}
//end hasIdentifierName:

-(CHChalkIdentifier*) identifierForName:(NSString*)name createClass:(Class)createClass
{
  CHChalkIdentifier* result = nil;
  NSString* key = name;
  if (key)
  {
    @synchronized(self)
    {
      result = [self->identifiersByName objectForKey:key];
      if (!result && createClass)
      {
        Class instanceClass = ![createClass isSubclassOfClass:[CHChalkIdentifier class]] ? nil : createClass;
        result = !instanceClass ? nil :
          [[[instanceClass alloc] initWithName:name caseSensitive:NO tokens:@[name] symbol:name symbolAsText:name symbolAsTeX:name] autorelease];
        if (result)
          [self->identifiersByName setObject:result forKey:name];
      }//end if (!result && createClass)
    }//end @synchronized(self)
  }//end if (key)
  return result;
}
//end identifierForName:createClass:

-(CHChalkIdentifier*) identifierForToken:(NSString*)token createClass:(Class)createClass
{
  __block CHChalkIdentifier* result = nil;
  if (token)
  {
    @synchronized(self)
    {
      [self->identifiersByName enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj matchesToken:token])
          result = obj;
        *stop |= (result != nil);
      }];
      if (!result && createClass)
      {
        Class instanceClass = ![createClass isSubclassOfClass:[CHChalkIdentifier class]] ? nil : createClass;
        result = !instanceClass ? nil :
          [[[instanceClass alloc] initWithName:token caseSensitive:NO tokens:@[token] symbol:token symbolAsText:token symbolAsTeX:token] autorelease];
        if (result)
          [self->identifiersByName setObject:result forKey:result.name];
      }//end if (!result && createClass)
    }//end @synchronized(self)
  }//end if (token)
  return result;
}
//end identifierForToken:createClass:

+(BOOL) isDefaultIdentifier:(CHChalkIdentifier*)identifier
{
  BOOL result = [[[self class] defaultIdentifiers] containsObject:identifier];
  return result;
}
//end isDefaultIdentifier

-(BOOL) isDefaultIdentifier:(CHChalkIdentifier*)identifier
{
  BOOL result = [[self class] isDefaultIdentifier:identifier];
  return result;
}
//end isDefaultIdentifier

+(BOOL) isDefaultIdentifierName:(NSString*)name
{
  __block BOOL result = NO;
  [[[self class] defaultIdentifiers] enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    BOOL isMatching = [obj matchesName:name];
    if (isMatching)
      result = true;
    *stop |= result;
  }];
  return result;
}
//end isDefaultIdentifierName:

-(BOOL) isDefaultIdentifierName:(NSString*)name
{
  BOOL result = [[self class] isDefaultIdentifierName:name];
  return result;
}
//end isDefaultIdentifierName:

+(BOOL) isDefaultIdentifierToken:(NSString*)token
{
  __block BOOL result = NO;
  [[[self class] defaultIdentifiers] enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    BOOL isMatching = [obj matchesToken:token];
    if (isMatching)
      result = true;
    *stop |= result;
  }];
  return result;
}
//end isDefaultIdentifierToken:

-(BOOL) isDefaultIdentifierToken:(NSString*)token
{
  BOOL result = [[self class] isDefaultIdentifierToken:token];
  return result;
}
//ed isDefaultIdentifierToken:

-(BOOL) isUsedIdentifierName:(NSString*)name
{
  BOOL result = NO;
  NSString* key = name;
  if (key)
  {
    @synchronized(self)
    {
      result = ([self->identifiersByName objectForKey:key] != nil);
    }//end @synchronized(self)
  }//end if (key)
  return result;
}
//end isUsedIdentifierName:

-(BOOL) isUsedIdentifierToken:(NSString*)token
{
  __block BOOL result = NO;
  @synchronized(self)
  {
    [self->identifiersByName enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      CHChalkIdentifier* identifier = [obj dynamicCastToClass:[CHChalkIdentifier class]];
      result |= [identifier.tokens containsObject:token];
      *stop |= result;
    }];
  }//end @synchronized(self)
  return result;
}
//end isUsedIdentifierToken:

-(CHChalkValue*) valueForIdentifier:(CHChalkIdentifier*)identifier
{
  CHChalkValue* result = nil;
  if (identifier)
  {
    @synchronized(self)
    {
      result = [self->identifierValues objectForKey:identifier];
    }//end @synchronized(self)
  }//end if (identifier)
  return result;
}
//end valueForIdentifier:

-(CHChalkValue*) valueForIdentifierName:(NSString*)name
{
  CHChalkValue* result = [self valueForIdentifier:[self identifierForName:name createClass:Nil]];
  return result;
}
//end valueForIdentifierName:

-(CHChalkValue*) valueForIdentifierToken:(NSString*)token
{
  CHChalkValue* result = [self valueForIdentifier:[self identifierForToken:token createClass:Nil]];
  return result;
}
//end valueForIdentifierToken:

-(BOOL) setValue:(CHChalkValue*)value forIdentifier:(CHChalkIdentifier*)identifier
{
  BOOL result = NO;
  if (identifier)
  {
    @synchronized(self)
    {
      if ([self addIdentifier:identifier replace:NO preventTokenConflict:YES])
      {
        if (!value)
          [self->identifierValues removeObjectForKey:identifier];
        else
          [self->identifierValues setObject:value forKey:identifier];
        result = YES;
      }//end if ([self addIdentifier:identifier replace:NO preventTokenConflict:YES])
    }//end @synchronized(self)
  }//end if (identifier)
  return result;
}
//end setValue:forIdentifier:

-(BOOL) setValue:(CHChalkValue*)value forIdentifierName:(NSString*)name
{
  BOOL result = [self setValue:value forIdentifier:[self identifierForName:name createClass:Nil]];
  return result;
}
//end setValue:forIdentifierName:

-(BOOL) setValue:(CHChalkValue*)value forIdentifierToken:(NSString*)token
{
  BOOL result = [self setValue:value forIdentifier:[self identifierForToken:token createClass:Nil]];
  return result;
}
//end setValue:forIdentifierToken:

-(BOOL) removeValueForIdentifier:(CHChalkIdentifier*)identifier
{
  BOOL result = [self setValue:nil forIdentifier:identifier];
  return result;
}
//end removeValueForIdentifier:

-(BOOL) removeValueForIdentifierName:(NSString*)name
{
  BOOL result = [self setValue:nil forIdentifierName:name];
  return result;
}
//end removeValueForIdentifierName:

-(BOOL) removeValueForIdentifierToken:(NSString*)token
{
  BOOL result = [self setValue:nil forIdentifierToken:token];
  return result;
}
//end removeValueForIdentifierToken:

-(NSArray<NSString*>*) constantsIdentifiersNamesMatchingPrefix:(NSString*)prefix
{
  NSArray<NSString*>* result = nil;
  if (prefix != nil)
  {
    BOOL isPrefixEmpty = [prefix isEqualToString:@""];
    NSMutableArray<NSString*>* array = [NSMutableArray<NSString*> array];
    NSEnumerator* enumerator = [self->identifiersByName keyEnumerator];
    id key = nil;
    while((key = [enumerator nextObject]))
    {
      NSString* name = [key dynamicCastToClass:[NSString class]];
      BOOL isMatch = isPrefixEmpty || [name startsWith:prefix options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
      if (isMatch)
      {
        id value = [self->identifiersByName objectForKey:key];
        CHChalkIdentifierConstant* identifierConstant = [value dynamicCastToClass:[CHChalkIdentifierConstant class]];
        if (identifierConstant != nil)
          [array safeAddObject:name];
      }//end if (isMatch)
    }//end for each value
    result = [array sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
      return [(NSString*)obj1 compare:(NSString*)obj2 options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
    }];
  }//end if (prefix != nil)
  return result;
}
//end constantsIdentifiersNamesMatchingPrefix:

@end
