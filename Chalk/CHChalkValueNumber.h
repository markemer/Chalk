//
//  CHChalkValueNumber.h
//  Chalk
//
//  Created by Pierre Chatelier on 09/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValueMovable.h"
#import "CHChalkValueScalar.h"

@class CHPresentationConfiguration;

@interface CHChalkValueNumber : CHChalkValueScalar <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable>

@property(nonatomic,readonly) NSInteger sign;//0 is not reliable, but -1 and 1 are

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
