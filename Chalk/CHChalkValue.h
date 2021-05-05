//
//  CHChalkValue.h
//  Chalk
//
//  Created by Pierre Chatelier on 16/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkUtils.h"
#import "CHChalkValueMovable.h"

@class CHChalkContext;
@class CHChalkError;
@class CHChalkToken;
@class CHPresentationConfiguration;
@class CHStreamWrapper;

@interface CHChalkValue : NSObject <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  CHChalkToken* token;
  int naturalBase;
  chalk_compute_flags_t evaluationComputeFlags;
  NSMutableArray* evaluationErrors;
}

@property(nonatomic,readonly,copy) CHChalkToken*         token;
@property(nonatomic)               int                   naturalBase;
@property(nonatomic)               chalk_compute_flags_t evaluationComputeFlags;
@property(nonatomic,readonly,copy) NSArray*              evaluationErrors;

@property(nonatomic,readonly) BOOL isZero;

-(instancetype) initWithToken:(CHChalkToken*)token context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token naturalBase:(int)naturalBase context:(CHChalkContext*)context;

-(void) replaceToken:(CHChalkToken*)token;

-(BOOL) isOne:(BOOL*)isOneIgnoringSign;
-(BOOL) negate;

-(void) adaptToComputeMode:(chalk_compute_mode_t)computeMode context:(CHChalkContext*)context;

-(void) addError:(CHChalkError*)error;
-(void) addError:(CHChalkError*)error context:(CHChalkContext*)context;
-(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

+(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context numberString:(NSString*)numberString presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
+(void) writeToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context operatorString:(NSString*)operatorString presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

+(instancetype) null;
+(instancetype) zeroWithToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(CHChalkValue*) simplify:(CHChalkValue**)pValue context:(CHChalkContext*)context;
+(NSMutableArray*) copyValues:(NSArray*)values withZone:(NSZone*)zone;
+(CHChalkValue*) finalizeValue:(CHChalkValue**)pValue context:(CHChalkContext*)context;

@end
