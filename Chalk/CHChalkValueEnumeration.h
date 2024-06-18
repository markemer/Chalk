//
//  CHChalkValueEnumeration.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValue.h"
#import "CHChalkValueMovable.h"
#import "CHChalkValueSubscriptable.h"

@interface CHChalkValueEnumeration : CHChalkValue <NSCopying, CHChalkValueMovable, CHChalkValueSubscriptable> {
  NSMutableArray* values;
}

@property(nonatomic,readonly) NSUInteger count;
@property(nonatomic,readonly) NSArray*   values;

-(instancetype) initWithToken:(CHChalkToken*)token context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token count:(NSUInteger)count value:(CHChalkValue*)value context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token values:(NSArray*)aValues context:(CHChalkContext*)context;

-(CHChalkValue*) valueAtIndex:(NSUInteger)index;
-(BOOL) setValue:(CHChalkValue*)value atIndex:(NSUInteger)index;
-(BOOL) addValue:(CHChalkValue*)value;

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
