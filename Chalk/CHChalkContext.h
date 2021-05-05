//
//  CHChalkContext.h
//  Chalk
//
//  Created by Pierre Chatelier on 26/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkUtils.h"

@class CHChalkContext;
@class CHChalkErrorContext;
@class CHChalkIdentifierManager;
@class CHChalkOperatorManager;
@class CHComputationConfiguration;
@class CHComputationEntryEntity;
@class CHPresentationConfiguration;
@class CHGmpPool;
@class CHParseConfiguration;

@protocol CHChalkContextHistoryDelegate
-(NSUInteger) chalkContext:(CHChalkContext*)chalkContext ageForComputationEntry:(CHComputationEntryEntity*)computationEntry;
-(CHComputationEntryEntity*) chalkContext:(CHChalkContext*)chalkContext computationEntryForAge:(NSUInteger)age;
-(CHComputationEntryEntity*) chalkContext:(CHChalkContext*)chalkContext computationEntryForUid:(NSInteger)uid;
@end

@interface CHChalkContext : NSObject <NSCopying> {
  CHParseConfiguration* parseConfiguration;
  CHComputationConfiguration* computationConfiguration;
  CHPresentationConfiguration* presentationConfiguration;
  NSUInteger hardMaxExponent;
  NSMutableDictionary* cachedSoftIntegerMaxDigitsByBase;
  NSMutableDictionary* cachedSoftIntegerMaxDenominatorDigitsByBase;
  NSMutableDictionary* cachedSoftFloatSignificandDigitsByBase;
  NSMutableDictionary* cachedSoftFloatDisplayDigitsByBase;
  BOOL concurrentEvaluations;
  BOOL outputRawToken;
  NSArray* basePrefixesSuffixes;
  NSMutableDictionary* basePrefixesSuffixesDictionary;
  CHChalkErrorContext* errorContext;
  NSMutableArray* memoryPool;
  CHChalkIdentifierManager* identifierManager;
  CHChalkOperatorManager* operatorManager;
  CHGmpPool* gmpPool;
  NSUInteger referenceAge;
  id<CHChalkContextHistoryDelegate> delegate;
}

@property(nonatomic,assign) NSUndoManager* undoManager;
@property(nonatomic,readonly,retain) CHParseConfiguration* parseConfiguration;
@property(nonatomic,readonly,retain) CHComputationConfiguration* computationConfiguration;
@property(nonatomic,readonly,retain) CHPresentationConfiguration* presentationConfiguration;
@property(nonatomic) BOOL concurrentEvaluations;
@property(nonatomic) BOOL outputRawToken;
@property(nonatomic,copy) NSArray* basePrefixesSuffixes;
@property(nonatomic,readonly,assign) CHChalkErrorContext* errorContext;
@property(nonatomic,retain) CHChalkIdentifierManager* identifierManager;
@property(nonatomic,retain) CHChalkOperatorManager* operatorManager;
@property(nonatomic,retain) CHGmpPool* gmpPool;
@property(nonatomic)        NSUInteger referenceAge;
@property(nonatomic,assign) id<CHChalkContextHistoryDelegate> delegate;

-(instancetype) initWithGmpPool:(CHGmpPool*)pool;

-(void) invalidateCaches;

-(NSUInteger) softIntegerMaxDigitsWithBase:(int)base;
-(NSUInteger) softFloatSignificandDigitsWithBase:(int)base;
-(NSUInteger) softFloatDisplayDigitsWithBase:(int)base;
-(NSArray*)   inputPrefixesForBase:(int)base;
-(NSArray*)   inputSuffixesForBase:(int)base;
-(NSString*)  inputPrefixForBase:(int)base;
-(NSString*)  inputSuffixForBase:(int)base;
-(NSArray*)   outputPrefixesForBase:(int)base;
-(NSArray*)   outputSuffixesForBase:(int)base;
-(NSString*)  outputPrefixForBase:(int)base;
-(NSString*)  outputSuffixForBase:(int)base;
-(int)        baseFromPrefix:(NSString*)prefix;
-(int)        baseFromSuffix:(NSString*)suffix;
-(void*) depoolMemoryForMpfrGetStr:(mpfr_srcptr)input nbDigits:(size_t)nbDigits;
-(void*) depoolMemoryForMpzGetStr:(mpz_srcptr)input base:(int)base;
-(void*) depoolMemoryForMpqGetStr:(mpq_srcptr)input base:(int)base;
-(void)  repoolMemory:(void*)memory;
+(void)  repoolMemory:(void*)memory forMpzOutBuffer:(void*)mpzOutBuffer context:(CHChalkContext*)context;
+(void)  repoolMemory:(void*)memory forMpqOutBuffer:(void*)mpqOutBuffer context:(CHChalkContext*)context;
+(void)  repoolMemory:(void*)memory forMpfrOutBuffer:(void*)mpfrOutBuffer context:(CHChalkContext*)context;

-(void) reset;
-(BOOL) reclaimResources;

-(CHComputationEntryEntity*) computationEntryForAge:(NSUInteger)age;
-(NSUInteger) ageForComputationEntry:(CHComputationEntryEntity*)computationEntry;

@end
