//
//  CHChalkValueParser.h
//  Chalk
//
//  Created by Pierre Chatelier on 23/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHChalkContext;
@class CHChalkToken;
@class CHChalkValue;

@interface CHChalkValueParser : NSObject {
  CHChalkToken* token;
  NSRange significandSignRange;
  NSRange significandBasePrefixRange;
  NSRange significandIntegerHeadRange;
  NSRange significandIntegerTailZerosRange;
  NSRange significandIntegerDigitsRange;
  NSRange significandDecimalSeparatorRange;
  NSRange significandFractHeadZerosRange;
  NSRange significandFractTailRange;
  NSRange significandFractDigitsRange;
  NSRange significandBaseSuffixRange;
  NSRange exponentSymbolRange;
  NSRange exponentSignRange;
  NSRange exponentDigitsBasePrefixRange;
  NSRange exponentDigitsRange;
  NSRange exponentDigitsBaseSuffixRange;
  NSInteger significandSign;
  NSInteger exponentSign;
  int     significandBase;
  int     exponentDigitsBase;
  int     exponentBaseToPow;
  BOOL    hasEllipsis;
}

@property(nonatomic,copy) CHChalkToken* token;
@property(nonatomic,readonly) NSUInteger significandDigitsCount;
@property(nonatomic,readonly) int significandBase;

-(id) initWithToken:(CHChalkToken*)token context:(CHChalkContext*)context;

-(void) resetAnalysis;
-(BOOL) analyzeWithContext:(CHChalkContext*)context;
-(CHChalkValue*) chalkValueWithContext:(CHChalkContext*)context;

@end
