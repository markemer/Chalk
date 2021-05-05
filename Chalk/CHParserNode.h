//
//  CHParserNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkUtils.h"

@class CHChalkContext;
@class CHChalkError;
@class CHChalkIdentifier;
@class CHChalkIdentifierManager;
@class CHChalkToken;
@class CHChalkValue;
@class CHPresentationConfiguration;
@class CHStreamWrapper;

@interface CHParserNode : NSObject<NSCopying> {
  @protected
  CHChalkToken* token;
  CHParserNode* parent;
  NSMutableArray* children;
  CHChalkValue* evaluatedValue;
  chalk_compute_flags_t evaluationComputeFlags;
  NSMutableArray* evaluationErrors;
}

+(instancetype) parserNodeWithToken:(CHChalkToken*)token;
-(instancetype) initWithToken:(CHChalkToken*)token;

@property(nonatomic,copy)            CHChalkToken* token;
@property(nonatomic,readonly,assign) CHParserNode* parent;
@property(nonatomic,readonly,retain) NSArray*      children;
@property(nonatomic,retain)          CHChalkValue* evaluatedValue;
@property(nonatomic)                 chalk_compute_flags_t evaluationComputeFlags;
@property(nonatomic,readonly)        chalk_compute_flags_t evaluationComputeFlagsCumulated;
@property(nonatomic,readonly)        BOOL isTerminal;
@property(nonatomic,readonly)        BOOL isPredicate;
@property(nonatomic,readonly,copy)   NSArray* evaluationErrors;

-(void) addChild:(CHParserNode*)node;

-(BOOL) resetEvaluationMatchingIdentifiers:(NSSet*)identifiers identifierManager:(CHChalkIdentifierManager*)identifierManager;
-(BOOL) isUsingIdentifier:(CHChalkIdentifier*)identifier identifierManager:(CHChalkIdentifierManager*)identifierManager;
-(void) checkFunctionIdentifiersWithContext:(CHChalkContext*)context outError:(CHChalkError**)outError;
-(NSSet*) dependingIdentifiersWithContext:(CHChalkContext*)context outError:(CHChalkError**)outError;
-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy;
-(void) performEvaluationWithChildren:(NSArray*)customChildren context:(CHChalkContext*)context lazy:(BOOL)lazy;

-(void) addError:(CHChalkError*)error;
-(void) addError:(CHChalkError*)error context:(CHChalkContext*)context;

-(void) writeDocumentHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeDocumentFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
