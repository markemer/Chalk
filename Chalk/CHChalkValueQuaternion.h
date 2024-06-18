//
//  CHChalkValueQuaternion.h
//  Chalk
//
//  Created by Pierre Chatelier on 09/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValueMovable.h"
#import "CHChalkValueScalar.h"

@class CHChalkValueNumber;

@interface CHChalkValueQuaternion : CHChalkValueScalar <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  CHChalkValueNumber* partReal;
  CHChalkValueNumber* partI;
  CHChalkValueNumber* partJ;
  CHChalkValueNumber* partK;
  BOOL partRealWrapped;
  BOOL partIWrapped;
  BOOL partJWrapped;
  BOOL partKWrapped;
}

@property(nonatomic,readonly,retain) CHChalkValueNumber* partReal;
@property(nonatomic,readonly,retain) CHChalkValueNumber* partI;
@property(nonatomic,readonly,retain) CHChalkValueNumber* partJ;
@property(nonatomic,readonly,retain) CHChalkValueNumber* partK;
@property(nonatomic,readonly)        BOOL isZero;
@property(nonatomic,readonly)        BOOL isReal;
@property(nonatomic,readonly)        BOOL isComplex;

+(instancetype) oneI;
+(instancetype) oneIWithToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(instancetype) oneJ;
+(instancetype) oneJWithToken:(CHChalkToken*)token context:(CHChalkContext*)context;
+(instancetype) oneK;
+(instancetype) oneKWithToken:(CHChalkToken*)token context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token
                     partReal:(CHChalkValueNumber*)partReal partRealWrapped:(BOOL)partRealWrapped
                     partI:(CHChalkValueNumber*)partI partIWrapped:(BOOL)partIWrapped
                     partJ:(CHChalkValueNumber*)partJ partJWrapped:(BOOL)partJWrapped
                     partK:(CHChalkValueNumber*)partK partKWrapped:(BOOL)partKWrapped
                   context:(CHChalkContext*)context;
-(void) setPartReal:(CHChalkValueNumber*)value wrapped:(BOOL)wrapped;
-(void) setPartI:(CHChalkValueNumber*)value wrapped:(BOOL)wrapped;
-(void) setPartJ:(CHChalkValueNumber*)value wrapped:(BOOL)wrapped;
-(void) setPartK:(CHChalkValueNumber*)value wrapped:(BOOL)wrapped;
-(CHChalkValueQuaternion*) conjugated;
-(CHChalkValueQuaternion*) conjugate;//in place, returns self

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
+(void) writeIToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
+(void) writeJToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
+(void) writeKToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
