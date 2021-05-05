//
//  NSObjectTreeNode.h
//  Chalk
//
//  Created by Pierre Chatelier on 03/04/09.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSObject (NSTreeNode)

-(BOOL) isDescendantOfItemInArray:(NSArray*)items parentSelector:(SEL)parentSelector;
-(BOOL) isDescendantOfNode:(id)node strictly:(BOOL)strictly parentSelector:(SEL)parentSelector;
-(id)   nextBrotherWithParentSelector:(SEL)parentSelector childrenSelector:(SEL)childrenSelector rootNodes:(NSArray*)rootNodes;
-(id)   prevBrotherWithParentSelector:(SEL)parentSelector childrenSelector:(SEL)childrenSelector rootNodes:(NSArray*)rootNodes;
+(NSArray*) minimumNodeCoverFromItemsInArray:(NSArray*)allItems parentSelector:(SEL)parentSelector;

@end
