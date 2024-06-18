//
//  CHChalkValueFormalSimple.h
//  Chalk
//
//  Created by Pierre Chatelier on 16/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValueFormal.h"

@interface CHChalkValueFormalSimple : CHChalkValueFormal <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  CHChalkValueNumberGmp* factor;
  CHChalkValueNumberGmp* power;
}

@property(nonatomic,retain) CHChalkValueNumberGmp* factor;
@property(nonatomic,retain) CHChalkValueNumberGmp* power;

@end
