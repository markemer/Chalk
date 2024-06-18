//
//  CHActionObject.h
//  Chalk
//
//  Created by Pierre Chatelier on 10/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHActionObject : NSObject {
  void (^actionBlock)(id);
}

@property(copy) void (^actionBlock)(id);

+(instancetype) actionObjectWithActionBlock:(void(^)(id))block;
-(instancetype) initWithActionBlock:(void(^)(id))block;

-(IBAction) action:(id)sender;

@end
