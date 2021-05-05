//
//  CHTableView.h
//  Chalk
//
//  Created by Pierre Chatelier on 28/07/05.
//  Copyright 2005-2015 Pierre Chatelier. All rights reserved.

//CHTableView presents custom text shortcuts from an text shortcut manager. I has user friendly capabilities

#import <Cocoa/Cocoa.h>

@interface CHTableView : NSTableView {
  NSIndexSet* draggedRowIndexes;//transient, used only during drag'n drop
  NSMutableDictionary* valueTransformers;
}

@property(nonatomic,retain) NSArrayController*  arrayController;
@property(retain)           NSUndoManager*      undoManager;
@property                   BOOL                allowPboardCopy;
@property                   BOOL                allowPboardPaste;
@property                   BOOL                allowDragDropMoving;
@property                   BOOL                allowDeletion;

-(NSValueTransformer*) valueTransformerForKey:(NSString*)key;
-(void) setValueTransformer:(NSValueTransformer*)valueTransformer forKey:(NSString*)key;

-(IBAction) edit:(id)sender;

//sent through the first responder chain
-(IBAction) undo:(id)sender;
-(IBAction) redo:(id)sender;
-(BOOL) validateMenuItem:(NSMenuItem*)sender;

@end
