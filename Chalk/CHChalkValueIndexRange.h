//
//  CHChalkValueIndexRange.h
//  Chalk
//
//  Created by Pierre Chatelier on 17/04/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValue.h"

@interface CHChalkValueIndexRange : CHChalkValue <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  NSRange range;
  BOOL joker;
  BOOL exclusive;
}

@property(nonatomic) NSRange range;
@property(nonatomic) BOOL joker;
@property(nonatomic) BOOL exclusive;
@property(nonatomic,readonly) BOOL isEmpty;

+(CHChalkValueIndexRange*) emptyValue;

-(instancetype) initWithToken:(CHChalkToken*)token range:(NSRange)range joker:(BOOL)joker exclusive:(BOOL)exclusive context:(CHChalkContext*)context;

@end
