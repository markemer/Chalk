//
//  CHParserMatrixNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 13/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHParserNode.h"
#import "CHParserSubscriptNode.h"

@interface CHParserMatrixNode : CHParserNode <CHParserNodeSubscriptable, NSCopying>

@end
