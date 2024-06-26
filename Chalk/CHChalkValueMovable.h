//
//  CHChalkValueMutable.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHChalkValue;

@protocol CHChalkValueMovable

-(CHChalkValue*) move;
-(BOOL) moveTo:(CHChalkValue*)dst;

@end
