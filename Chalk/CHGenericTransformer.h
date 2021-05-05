//
//  CHGenericTransformer.h
//  Chalk
//
//  Created by Pierre Chatelier on 11/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHGenericTransformer : NSValueTransformer {
  id (^transformBlock)(id);
  id (^reverseTransformBlock)(id);
}

+(NSString*) name;

+(instancetype) transformerWithBlock:(id (^)(id))transformBlock reverse:(id (^)(id))reverseBlock;
-(instancetype) initWithBlock:(id (^)(id))transformBlock reverse:(id (^)(id))reverseBlock;

@end
