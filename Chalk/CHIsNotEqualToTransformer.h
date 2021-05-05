//
//  CHIsNotEqualToTransformer.h
//  Chalk
//
//  Created by Pierre Chatelier on 26/04/09.
//  Copyright 2005-2015 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CHIsNotEqualToTransformer : NSValueTransformer {
  id reference;
}

+(NSString*) name;

+(id) transformerWithReference:(id)reference;
-(id) initWithReference:(id)reference;

@end
