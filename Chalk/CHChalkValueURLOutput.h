//
//  CHChalkValueURLOutput.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueURL.h"

@interface CHChalkValueURLOutput : CHChalkValueURL <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable>

-(void) write:(NSData*)data append:(BOOL)append context:(CHChalkContext*)context;

@end
