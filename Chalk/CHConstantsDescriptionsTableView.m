//
//  CHConstantsDescriptionsTableView.m
//  Chalk
//
//  Created by Pierre Chatelier on 03/04/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHConstantsDescriptionsTableView.h"

@implementation CHConstantsDescriptionsTableView

-(NSDragOperation) draggingSession:(NSDraggingSession*)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
  return NSDragOperationCopy;
}
//end draggingSession:sourceOperationMaskForDraggingContext:

@end
