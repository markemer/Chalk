//
//  CHParserValueIndexRangeNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 16/04/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserValueNode.h"

@interface CHParserValueIndexRangeNode : CHParserValueNode <NSCopying> {
  BOOL joker;
  BOOL exclusive;
}

@property(nonatomic) BOOL joker;
@property(nonatomic) BOOL exclusive;

+(instancetype) parserNodeWithToken:(CHChalkToken*)token joker:(BOOL)joker;
-(instancetype) initWithToken:(CHChalkToken*)token joker:(BOOL)joker;

@end
