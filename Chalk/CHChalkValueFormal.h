//
//  CHChalkValueFormal.h
//  Chalk
//
//  Created by Pierre Chatelier on 16/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValue.h"

@class CHChalkValueNumberGmp;

@interface CHChalkValueFormal : CHChalkValue <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  CHChalkValueNumberGmp* baseValue;
  CHChalkValueNumberGmp* value;
}

@property(nonatomic,retain) CHChalkValueNumberGmp* baseValue;
@property(nonatomic,retain) CHChalkValueNumberGmp* value;

@end
