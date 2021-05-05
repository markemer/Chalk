//
//  CHChalkValueSubscriptable.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHChalkContext;
@class CHChalkValue;
@class CHChalkValueSubscript;

@protocol CHChalkValueSubscriptable

-(CHChalkValue*) valueAtSubscript:(CHChalkValueSubscript*)subscript context:(CHChalkContext*)context;
-(BOOL) setValue:(CHChalkValue*)value atSubscript:(CHChalkValueSubscript*)subscript context:(CHChalkContext*)context;

@end
