//
//  CHChalkValueSubscript.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValue.h"
#import "CHChalkValueMovable.h"

@interface CHChalkValueSubscript : CHChalkValue <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  NSArray* indices;
}

@property(nonatomic,readonly)      NSUInteger count;
@property(nonatomic,readonly,copy) NSArray* indices;

-(instancetype) initWithToken:(CHChalkToken*)token indices:(NSArray*)indices context:(CHChalkContext*)context;

-(id) indexAtIndex:(NSUInteger)index;

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
