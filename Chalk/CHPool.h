//
//  CHPool.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/05/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id (^constructionBlock_t)(void);

@interface CHPool : NSObject {
  NSUInteger maxCapacity;
  constructionBlock_t defaultConstructionBlock;
  NSMutableArray* pool;
}

-(instancetype) initWithMaxCapacity:(NSUInteger)maxCapacity;
-(instancetype) initWithMaxCapacity:(NSUInteger)maxCapacity defaultConstruction:(constructionBlock_t)constructionBlock;
-(void) repool:(id)object;
-(id) depool;
-(id) depoolUsingConstruction:(constructionBlock_t)constructionBlock;

@end
