//
//  CHTableView.m
//  Chalk
//
//  Created by Pierre Chatelier on 28/07/05.
//  Copyright 2005-2015 Pierre Chatelier. All rights reserved.

//CHTableView presents custom text shortcuts from an text shortcuts manager. I has user friendly capabilities

#import "CHTableView.h"

#import "NSArrayControllerExtended.h"
#import "NSObjectExtended.h"

@interface CHTableView ()
@property(readonly,assign) NSIndexSet* draggedRowIndexes;
@property(readonly,copy)   NSString*   pboardType;
-(void) textDidEndEditing:(NSNotification *)aNotification;
-(void) rebind;
@end

@implementation CHTableView

@synthesize arrayController;
@synthesize allowDragDropMoving;
@synthesize allowDeletion;
@synthesize undoManager;
@synthesize draggedRowIndexes;
@dynamic    pboardType;

-(id) initWithCoder:(NSCoder*)coder
{
  if ((!(self = [super initWithCoder:coder])))
    return nil;
  self->valueTransformers = [[NSMutableDictionary alloc] init];
  [self registerForDraggedTypes:[NSArray arrayWithObject:self.pboardType]];
  return self;
}
//end initWithCoder:

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->valueTransformers release];
  [self->arrayController release];
  self.undoManager = nil;
  [super dealloc];
}
//end dealloc

-(void) awakeFromNib
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:self];
}
//end awakeFromNib

-(void) setArrayController:(NSArrayController*)value
{
  if (value != self->arrayController)
  {
    [self->arrayController release];
    self->arrayController = [value retain];
    [self rebind];
  }//end if (value != self->arrayController)
}
//end setArrayController:

-(NSValueTransformer*) valueTransformerForKey:(NSString*)key
{
  NSValueTransformer* result = !key ? nil :
    [[self->valueTransformers objectForKey:key] dynamicCastToClass:[NSValueTransformer class]];
  return result;
}
//end valueTransformerForKey:

-(void) setValueTransformer:(NSValueTransformer*)valueTransformer forKey:(NSString*)key
{
  if (key)
  {
    if (!valueTransformer)
      [self->valueTransformers removeObjectForKey:key];
    else
      [self->valueTransformers setObject:valueTransformer forKey:key];
    [self rebind];
  }//end if (key)
}
//end setValueTransformer:forKey:

-(void) rebind
{
  [self bind:NSSelectionIndexesBinding toObject:self->arrayController withKeyPath:NSSelectionIndexesBinding options:nil];
  NSArray* tableColumns = self.tableColumns;
  [self bind:NSContentBinding toObject:self->arrayController withKeyPath:@"arrangedObjects"
     options:nil];
  for(NSTableColumn* tableColumn in tableColumns)
  {
    NSString* key = tableColumn.identifier;
    NSValueTransformer* valueTransformer = [self valueTransformerForKey:key];
    NSDictionary* options = !valueTransformer ? nil :
      @{NSValueTransformerBindingOption:valueTransformer};
    [tableColumn bind:NSValueBinding toObject:self->arrayController
      withKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", key] options:options];
  }//end for each tableColumn
}
//end rebind

-(BOOL) acceptsFirstMouse:(NSEvent*)theEvent
{
  NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  NSInteger row = [self rowAtPoint:point];
  [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
  return YES;
}
//end acceptsFirstMouse

-(void) keyDown:(NSEvent*)theEvent
{
  [super interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
  if (([theEvent keyCode] == 36) || ([theEvent keyCode] == 52) || ([theEvent keyCode] == 49))//Enter, space or ?? What did I do ???
    [self edit:self];
}
//end keyDown:

//edit selected row
-(IBAction) edit:(id)sender
{
  NSInteger selectedRow = [self selectedRow];
  if (selectedRow >= 0)
    [self editColumn:0 row:selectedRow withEvent:nil select:YES];
}
//end edit:

-(IBAction) undo:(id)sender
{
  [self.undoManager undo];
}
//end undo:

-(IBAction) redo:(id)sender
{
  [self.undoManager redo];
}
//end redo:

-(BOOL) validateMenuItem:(NSMenuItem*)sender
{
  BOOL ok = YES;
  if (sender.action == @selector(undo:))
  {
    ok = [self.undoManager canUndo];
    NSString* title = [self.undoManager undoMenuItemTitle];
    if (title)
      [sender setTitleWithMnemonic:title];
  }//end if (sender.action == @selector(undo:))
  else if (sender.action== @selector(redo:))
  {
    ok = [self.undoManager canRedo];
    NSString* title = [self.undoManager redoMenuItemTitle];
    if (title)
      [sender setTitleWithMnemonic:title];
  }//end if (sender.action == @selector(redo:))
  else if (sender.action == @selector(copy:))
    ok = NO;//self.allowPboardCopy && (self.selectedRowIndexes.count > 0);
  else if (sender.action == @selector(paste:))
  {
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    NSArray* items = !self.allowPboardPaste ? nil : [[pboard propertyListForType:self.pboardType] dynamicCastToClass:[NSArray class]];
    ok = NO;//self.allowPboardPaste && (items.count > 0);
  }//end if (sender.action == @selector(paste:))
  return ok;
}
//end validateMenuItem:

-(void) deleteBackward:(id)sender
{
  if (self.allowDeletion)
    [self.arrayController remove:sender];
}
//end deleteBackward:

-(void) moveUp:(id)sender
{
  NSInteger selectedRow = [self selectedRow];
  if (selectedRow > 0)
    --selectedRow;
  [self selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
  [self scrollRowToVisible:selectedRow];
}
//end moveUp:

-(void) moveDown:(id)sender
{
  NSInteger selectedRow = [self selectedRow];
  if ((selectedRow >= 0) && (selectedRow+1 < [self numberOfRows]))
    ++selectedRow;
  [self selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
  [self scrollRowToVisible:selectedRow];
}
//end moveDown:

//prevents from selecting next line when finished editing
-(void) textDidEndEditing:(NSNotification *)aNotification
{
  NSInteger selectedRow = [self selectedRow];
  [super textDidEndEditing:aNotification];
  [self selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
}
//end textDidEndEditing:

//delegate methods
-(void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
  NSUInteger lastIndex = [[self selectedRowIndexes] lastIndex];
  [self scrollRowToVisible:lastIndex];
}
//end tableViewSelectionDidChange:

#pragma mark copy/paste

-(IBAction) copy:(id)sender
{
  if (self.allowPboardCopy)
  {
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    //[self tableView:self writeRowsWithIndexes:self.selectedRowIndexes toPasteboard:pboard];
  }//end if (self.allowPboardCopy)
}
//end copy:

-(IBAction) paste:(id)sender
{
  if (self.allowPboardPaste)
  {
    NSPasteboard* pboard = [NSPasteboard generalPasteboard];
    [self tableView:self writeRowsWithIndexes:self.selectedRowIndexes toPasteboard:pboard];
  }//end if (self.allowPboardCopy)
}
//end paste:

#pragma mark drag'n drop
//drag'n drop for moving rows

-(NSString*) pboardType
{
  return [NSString stringWithFormat:@"%@%p", NSStringFromClass(self.class), self];
}
//end pboardType

-(BOOL) tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
  BOOL result = NO;
  if (self.allowDragDropMoving)
  {
    self->draggedRowIndexes = rowIndexes;
    NSArray* selectedObjects = [self.arrayController selectedObjects];
    [pboard declareTypes:[NSArray arrayWithObject:self.pboardType] owner:self];
    [pboard setPropertyList:[NSKeyedArchiver archivedDataWithRootObject:selectedObjects] forType:self.pboardType];
    result = YES;
  }//end if (self.allowDragDropMoving)
  return result;
}
//end tableView:writeRowsWithIndexes:toPasteboard:

-(NSDragOperation) tableView:(NSTableView*)tableView validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
  NSDragOperation result = NSDragOperationNone;
  if (self.allowDragDropMoving)
  {
    NSPasteboard* pboard = [info draggingPasteboard];
    CHTableView* draggingSource = [info.draggingSource dynamicCastToClass:[CHTableView class]];
    NSIndexSet* indexSet =  draggingSource.draggedRowIndexes;
    BOOL ok = (tableView == draggingSource) && pboard &&
              [pboard availableTypeFromArray:[NSArray arrayWithObject:self.pboardType]] &&
              [pboard propertyListForType:self.pboardType] &&
              (operation == NSTableViewDropAbove) &&
              indexSet && ([indexSet firstIndex] != (unsigned int)row) && ([indexSet firstIndex]+1 != (unsigned int)row);
    result = ok ? NSDragOperationGeneric : NSDragOperationNone;
  }//end if (self.allowDragDropMoving)
  return result;
}
//end tableView:validateDrop:proposedRow:proposedDropOperation:

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
  BOOL result = NO;
  if (self.allowDragDropMoving)
  {
    CHTableView* draggingSource = [info.draggingSource dynamicCastToClass:[CHTableView class]];
    NSIndexSet* indexSet = draggingSource.draggedRowIndexes;
    [self.arrayController moveObjectsAtIndices:indexSet toIndex:(NSUInteger)row];
    self->draggedRowIndexes = nil;
  }//end if (self.allowDragDropMoving)
  return result;
}
//end tableView:acceptDrop:row:dropOperation:

@end
