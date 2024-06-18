//
//  CHChalkIdentifierManagerWrapper.h
//  Chalk
//
//  Created by Pierre Chatelier on 18/05/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkIdentifierManager.h"

@interface CHChalkIdentifierManagerWrapper : CHChalkIdentifierManager {
  NSMapTable* identifierDynamicValues;
}

-(CHChalkValue*) valueForIdentifier:(CHChalkIdentifier*)identifier;
-(BOOL) setValue:(CHChalkValue*)value forIdentifier:(CHChalkIdentifier*)identifier;
-(void) resetDynamicIdentifierValues;

@end
