//
//  CHArrayController.h
//  Chalk
//
//  Created by Pierre Chatelier on 09/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef id(^NSArrayControllerObjectCreator_t)(void);

@interface CHArrayController : NSArrayController {
  id(^objectCreator)(void);
}

@property(copy) id(^objectCreator)(void);

@end
