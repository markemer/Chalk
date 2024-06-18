//
//  CHParserValueStringNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserValueNode.h"

@interface CHParserValueStringNode : CHParserValueNode <NSCopying>

@property(readonly,copy) NSString* innerString;

@end
