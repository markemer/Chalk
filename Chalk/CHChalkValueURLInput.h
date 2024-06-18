//
//  CHChalkValueURLInput.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueURL.h"

@interface CHChalkValueURLInput : CHChalkValueURL <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  CHChalkValue* urlValue;
}

@property(readonly,retain) CHChalkValue* urlValue;

-(void) performEvaluationWithContext:(CHChalkContext*)context;

@end
