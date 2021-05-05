//
//  CHParserIdentifierNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 13/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHParserValueNode.h"

@class CHChalkIdentifier;

@interface CHParserIdentifierNode : CHParserValueNode <NSCopying> {
  CHChalkIdentifier* cachedIdentifier;
}

-(CHChalkIdentifier*) identifierWithContext:(CHChalkContext*)context;

@end
