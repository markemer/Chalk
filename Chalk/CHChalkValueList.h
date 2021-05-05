//
//  CHChalkValueList.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/11/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValueEnumeration.h"

@interface CHChalkValueList : CHChalkValueEnumeration <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable, CHChalkValueSubscriptable> {
}

-(void) writeHeaderToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) writeFooterToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end