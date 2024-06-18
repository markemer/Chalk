//
//  CHChalkValueMatrix.h
//  Chalk
//
//  Created by Pierre Chatelier on 09/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValueMovable.h"
#import "CHChalkValueScalar.h"
#import "CHChalkValueSubscriptable.h"

@interface CHChalkValueMatrix : CHChalkValue <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable, CHChalkValueSubscriptable> {
  NSUInteger rowsCount;
  NSUInteger colsCount;
  NSMutableArray* values;
}

@property(nonatomic,readonly) NSUInteger rowsCount;
@property(nonatomic,readonly) NSUInteger colsCount;
@property(nonatomic,readonly,assign) NSArray* values;

+(instancetype) identity:(NSUInteger)dimension context:(CHChalkContext*)context;

-(instancetype) initWithToken:(CHChalkToken*)token rowsCount:(NSUInteger)rowsCount colsCount:(NSUInteger)colsCount value:(CHChalkValueScalar*)value
                      context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token rowsCount:(NSUInteger)rowsCount colsCount:(NSUInteger)colsCount values:(NSArray*)aValues
                      context:(CHChalkContext*)context;

-(void) fill:(CHChalkValue*)value context:(CHChalkContext*)context;
-(CHChalkValue*) valueAtRow:(NSUInteger)row col:(NSUInteger)col;
-(BOOL) setValue:(CHChalkValue*)value atRow:(NSUInteger)row col:(NSUInteger)col;

-(CHChalkValueMatrix*) transposedWithContext:(CHChalkContext*)context;
-(CHChalkValueMatrix*) transposeWithContext:(CHChalkContext*)context;//in place, returns self on success, otherwise nil

-(CHChalkValue*) traceWithContext:(CHChalkContext*)context;
-(CHChalkValue*) determinantWithContext:(CHChalkContext*)context;
-(CHChalkValueMatrix*) invertedWithContext:(CHChalkContext*)context;
-(CHChalkValueMatrix*) invertWithContext:(CHChalkContext*)context;//in place, returns self on success, otherwise nil

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
