//
//  CHGraphWindowController.m
//  Chalk
//
//  Created by Pierre Chatelier on 08/05/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHGraphDocument.h"

#import "CHActionObject.h"
#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkIdentifier.h"
#import "CHChalkIdentifierManager.h"
#import "CHChalkIdentifierVariable.h"
#import "CHChalkItemDependencyManager.h"
#import "CHChalkOperatorManager.h"
#import "CHChalkToken.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueToStringTransformer.h"
#import "CHColorWell.h"
#import "CHComputationConfiguration.h"
#import "CHGenericTransformer.h"
#import "CHGmpPool.h"
#import "CHGraphAxis.h"
#import "CHGraphAxisControl.h"
#import "CHGraphCurveParametersViewController.h"
#import "CHUserVariableItem.h"
#import "CHGraphContext.h"
#import "CHGraphCurve.h"
#import "CHGraphCurveCachedData.h"
#import "CHGraphCurveItem.h"
#import "CHGraphScale.h"
#import "CHGraphView.h"
#import "CHInspectorView.h"
#import "CHParseConfiguration.h"
#import "CHParser.h"
#import "CHParserNode.h"
#import "CHPreferencesController.h"
#import "CHStreamWrapper.h"
#import "CHTableView.h"
#import "CHUtils.h"
#import "CHViewColor.h"

#import "NSIndexSetExtended.h"
#import "NSMenuExtended.h"
#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"
#import "NSSegmentedControlExtended.h"
#import "NSStringExtended.h"
#import "NSViewExtended.h"
#import "NSWindowExtended.h"
#import "NSWorkspaceExtended.h"

@interface CHGraphEnabledTableCellView : NSTableCellView
@property(assign) IBOutlet NSButton* checkBox;
@property(assign) IBOutlet NSProgressIndicator* progressIndicator;
@end

@implementation CHGraphEnabledTableCellView
@end

@interface CHGraphCurveNameTextField : NSTextField
@property(nonatomic,retain) CHGraphCurveItem* curveItem;
@end

@implementation CHGraphCurveNameTextField
@synthesize curveItem;

+(void) initialize
{
  [self exposeBinding:@"curveItem"];
}
//end initialize

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.curveItem = nil;
  [super dealloc];
}
//end dealloc

-(void) setCurveItem:(CHGraphCurveItem*)value
{
  if (value != self->curveItem)
  {
    [self willChangeValueForKey:@"curveItem"];
    if (self->curveItem.curve)
      [[NSNotificationCenter defaultCenter] removeObserver:self name:CHChalkParseDidEndNotification object:self->curveItem.curve];
    [self->curveItem release];
    self->curveItem = [value retain];
    if (self->curveItem.curve)
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notified:) name:CHChalkParseDidEndNotification object:self->curveItem.curve];
    [self didChangeValueForKey:@"curveItem"];
  }//end if (value != self->curveItem)
}
//end setCurveItem:

-(void) notified:(NSNotification*)notification
{
  if ([notification.name isEqualToString:CHChalkParseDidEndNotification])
  {
    CHGraphCurve* curve = self->curveItem.curve;
    BOOL hasError = (curve.parseError != nil);
    NSTextFieldCell* textFieldCell = [self.cell dynamicCastToClass:[NSTextFieldCell class]];
    textFieldCell.backgroundColor = hasError ? [NSColor colorWithCalibratedRed:253/255. green:177/255. blue:179/255. alpha:1.] : [NSColor clearColor];
    textFieldCell.drawsBackground = hasError;
  }//end if ([notification.name isEqualToString:CHChalkParseDidEndNotification])
}
//end notified:

@end

@interface CHUserVariableItemTextField : NSTextField
@property(nonatomic,retain) CHUserVariableItem* userVariableItem;
@end

@implementation CHUserVariableItemTextField
@synthesize userVariableItem;

+(void) initialize
{
  [self exposeBinding:@"userVariableItem"];
}
//end initialize

-(void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.userVariableItem = nil;
  [super dealloc];
}
//end dealloc

-(void) setUserVariableItem:(CHUserVariableItem*)value
{
  if (value != self->userVariableItem)
  {
    [self willChangeValueForKey:@"userVariableItem"];
    if (self->userVariableItem)
      [[NSNotificationCenter defaultCenter] removeObserver:self name:CHChalkParseDidEndNotification object:self->userVariableItem];
    if (self->userVariableItem)
      [[NSNotificationCenter defaultCenter] removeObserver:self name:CHChalkEvaluationDidEndNotification object:self->userVariableItem];
    [self->userVariableItem release];
    self->userVariableItem = [value retain];
    if (self->userVariableItem)
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notified:) name:CHChalkParseDidEndNotification object:self->userVariableItem];
    if (self->userVariableItem)
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notified:) name:CHChalkEvaluationDidEndNotification object:self->userVariableItem];
    [self didChangeValueForKey:@"userVariableItem"];
  }//end if (value != self->userVariableItem)
}
//end setUserVariableItem:

-(void) notified:(NSNotification*)notification
{
  if ([notification.name isEqualToString:CHChalkParseDidEndNotification] || [notification.name isEqualToString:CHChalkEvaluationDidEndNotification])
  {
    BOOL hasError =
      self->userVariableItem.parseError || self->userVariableItem.chalkContext.errorContext.error;
    BOOL circularDependency = self->userVariableItem.hasCircularDependency;
    NSTextFieldCell* textFieldCell = [self.cell dynamicCastToClass:[NSTextFieldCell class]];
    textFieldCell.backgroundColor = hasError || circularDependency ? [NSColor colorWithCalibratedRed:253/255. green:177/255. blue:179/255. alpha:1.] : [NSColor clearColor];
    textFieldCell.drawsBackground = hasError || circularDependency;
  }//end if ([notification.name isEqualToString:CHChalkParseDidEndNotification] || [notification.name isEqualToString:CHChalkEvaluationDidEndNotification])
}
//end notified:

@end

@interface CHGraphDocument()
-(CHGraphCurveItem*) curveItemForCurve:(CHGraphCurve*)curve;
-(void) updateInputControls;
-(void) tableViewSelectionDidChange:(NSNotification*)notification;
-(void) updateGraphData:(BOOL)invalidateCaches;
-(BOOL) updateAutoMajorSteps;
-(IBAction) updateGraphAxisData:(id)sender;
-(IBAction) updateGraphAxisUI:(id)target;
@end

@implementation CHGraphDocument

@synthesize graphFont;
@synthesize inspectorLeftView;
@synthesize inspectorRightView;
@dynamic currentCurve;
@dynamic currentCurveItem;

+(NSString*) defaultDocumentFileName
{
  NSString* result = @"Graph.chalk";
  return result;
}
//end defaultDocumentFileName

-(id) init
{
  if (!((self = [super init])))
    return nil;
  self->gmpPool = [[CHGmpPool alloc] initWithCapacity:1024];
  self->chalkContext = [[CHChalkContext alloc] initWithGmpPool:self->gmpPool];
  self->chalkContext.identifierManager = [CHChalkIdentifierManager identifierManagerWithDefaults:YES];
  self->chalkContext.operatorManager = [CHChalkOperatorManager operatorManagerWithDefaults:YES];
  [self->chalkContext reset];
  self->chalkContext.computationConfiguration.computeMode = CHALK_COMPUTE_MODE_APPROX_INTERVALS;
  self->chalkContext.computationConfiguration.propagateNaN = NO;
  self->chalkContext.concurrentEvaluations = YES;
  self->curvesController = [[NSArrayController alloc] init];
  [self->curvesController setAutomaticallyPreparesContent:NO];
  self->userVariableItemsController = [[NSArrayController alloc] init];
  self->userVariableItemsController.sortDescriptors =
    @[[NSSortDescriptor sortDescriptorWithKey:CHUserVariableItemNameKey ascending:YES]];
  self->userVariableItemsController.automaticallyRearrangesObjects = YES;
  [self->userVariableItemsController setAutomaticallyPreparesContent:NO];
  self->detachedCurve = [[CHGraphCurve alloc] initWithContext:self->chalkContext];
  self->detachedCurve.delegate = self;
  self->detachedCurveItem = [[CHGraphCurveItem alloc] initWithCurve:self->detachedCurve];
  self->detachedCurveItem.delegate = self;

  self->dependencyManager = [[CHChalkItemDependencyManager alloc] init];
  CHChalkIdentifierManager* identifierManager = self->chalkContext.identifierManager;
  [identifierManager identifierForToken:@"x" createClass:[CHChalkIdentifier class]];//reserve
  [identifierManager identifierForToken:@"y" createClass:[CHChalkIdentifier class]];//reserve
  [self->chalkContext.identifierManager.variablesIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHChalkIdentifierVariable* variableIdentifier = [obj dynamicCastToClass:[CHChalkIdentifierVariable class]];
    CHUserVariableItem* userVariableItem = !variableIdentifier ? nil :
      [[[CHUserVariableItem alloc] initWithIdentifier:variableIdentifier isDynamic:NO input:nil evaluatedValue:nil context:self->chalkContext managedObjectContext:nil] autorelease];
    if (userVariableItem)
    {
      [self->dependencyManager addItem:userVariableItem];
      [self->userVariableItemsController addObject:userVariableItem];
    }//end if (userVariableItem)
  }];
  self->chalkValueToStringTransformer = [[CHChalkValueToStringTransformer alloc] initWithContext:self->chalkContext];
  return self;
}
//end init

-(void) dealloc
{
  [self->graphFont release];
  self->graphFont = nil;
  [self->axis1Control removeObserver:self forKeyPath:CHAxisColorBinding];
  [self->axis2Control removeObserver:self forKeyPath:CHAxisColorBinding];
  [self->curvesController removeObserver:self forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", NSEnabledBinding]];
  [self->curvesController removeObserver:self forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", CHGraphCurveItemCurveColorKey]];
  [self->curvesController removeObserver:self forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", CHGraphCurveItemPredicateColorFalseKey]];
  [self->curvesController removeObserver:self forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", CHGraphCurveItemPredicateColorTrueKey]];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->graphCurveParametersViewController release];
  [self->curveParametersPopOver release];
  [self->axis1Control release];
  [self->axis2Control release];
  [self->curvesController release];
  [self->userVariableItemsController release];
  [self->dependencyManager release];
  [self->chalkContext release];
  [self->gmpPool release];
  [self->detachedCurve release];
  [self->detachedCurveItem release];
  [self->chalkValueToStringTransformer release];
  [super dealloc];
}
//end dealloc

-(void) windowWillClose:(NSNotification*)notification
{
  [self->graphView removeCurve:self->detachedCurve];
}
//end windowWillClose:

-(NSString*) windowNibName
{
  return @"CHGraphDocument";
}
//end windowNibName

-(void) windowControllerDidLoadNib:(NSWindowController*)aController
{
  [super windowControllerDidLoadNib:aController];
  
  self->graphBackgroundColorView.backgroundColor = [NSColor whiteColor];
  self->backgroundColorWell.allowAlpha = YES;
  self->backgroundColorWell.color = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0];
  self->backgroundColorWell.toolTip = NSLocalizedString(@"Graph background color", @"");
  self->graphFontButton.toolTip = NSLocalizedString(@"Graph font", @"");
  
  [self->inputProgressIndicator bind:@"animated" toObject:self->detachedCurveItem withKeyPath:@"isUpdating" options:nil];
  [self->inputProgressIndicator bind:NSHiddenBinding toObject:self->detachedCurveItem withKeyPath:@"isUpdating" options:@{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];

  [self->graphView addCurve:self->detachedCurve];
  NSSegmentedCell* segmentedCell = [self->graphActionSegmentedControl.cell dynamicCastToClass:[NSSegmentedCell class]];
  [segmentedCell setToolTip:NSLocalizedString(@"No action", @"") forSegment:0];
  [segmentedCell setToolTip:NSLocalizedString(@"Move by dragging", @"") forSegment:1];
  [segmentedCell setToolTip:NSLocalizedString(@"Zoom in", @"") forSegment:2];
  [segmentedCell setToolTip:NSLocalizedString(@"Zoom out", @"") forSegment:3];
  [segmentedCell setTag:CHGRAPH_ACTION_CURSOR forSegment:0];
  [segmentedCell setTag:CHGRAPH_ACTION_DRAG forSegment:1];
  [segmentedCell setTag:CHGRAPH_ACTION_ZOOM_IN forSegment:2];
  [segmentedCell setTag:CHGRAPH_ACTION_ZOOM_OUT forSegment:3];
  [self->graphActionSegmentedControl selectSegmentWithTag:self->graphView.currentAction];
  [self->graphActionSegmentedControl centerRelativelyTo:self->graphView horizontally:YES vertically:NO];

  [self->graphSnapshotPopUpButton.menu removeAllItems];
  [self->graphSnapshotPopUpButton.menu addItemWithTitle:[NSString stringWithFormat:@"%@...",NSLocalizedString(@"Snapshot", @"")] tag:0 action:@selector(makeSnapshot:) target:self];
  [self->graphSnapshotPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Copy PDF to clipboard", @"") tag:1 action:@selector(makeSnapshot:) target:self];
  [self->graphSnapshotPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Copy PNG to clipboard", @"") tag:2 action:@selector(makeSnapshot:) target:self];
  [self->graphSnapshotPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Create PDF file on desktop", @"") tag:3 action:@selector(makeSnapshot:) target:self];
  [self->graphSnapshotPopUpButton.menu addItemWithTitle:NSLocalizedString(@"Create PNG file on desktop", @"") tag:4 action:@selector(makeSnapshot:) target:self];
  [self->graphSnapshotPopUpButton sizeToFit];
  [self->graphSnapshotPopUpButton centerRelativelyTo:self->graphView horizontally:YES vertically:NO];
  
  self->axis1Control = [[CHGraphAxisControl alloc] initWithNibName:@"CHGraphAxisControl" bundle:[NSBundle mainBundle]];
  self->axis2Control = [[CHGraphAxisControl alloc] initWithNibName:@"CHGraphAxisControl" bundle:[NSBundle mainBundle]];
  [self->axis1ControlWrapper addSubview:self->axis1Control.view];
  [self->axis2ControlWrapper addSubview:self->axis2Control.view];
  self->axis1Control.axisTitle = NSLocalizedString(@"x axis", @"");
  self->axis2Control.axisTitle = NSLocalizedString(@"y axis", @"");
  for(CHGraphAxisControl* axisControl in @[self->axis1Control, self->axis2Control])
  {
    axisControl.minTextField.target = self;
    axisControl.minTextField.action = @selector(updateGraphAxisData:);
    axisControl.minStepper.delegate = self;
    axisControl.maxTextField.target = self;
    axisControl.maxTextField.action = @selector(updateGraphAxisData:);
    axisControl.maxStepper.delegate = self;
    axisControl.centerButton.target = self;
    axisControl.centerButton.action = @selector(centerAxes:);
    axisControl.scaleTypeButton.target = self;
    axisControl.scaleTypeButton.action = @selector(updateGraphAxisData:);
    axisControl.scaleTypeBaseTextField.target = self;
    axisControl.scaleTypeBaseTextField.action = @selector(updateGraphAxisData:);
    axisControl.scaleTypeBaseStepper.delegate = self;
    axisControl.gridMajorAutoCheckBox.target = self;
    axisControl.gridMajorAutoCheckBox.action = @selector(updateGraphAxisData:);
    axisControl.gridMajorTextField.target = self;
    axisControl.gridMajorTextField.action = @selector(updateGraphAxisData:);
    axisControl.gridMajorStepper.delegate = self;
    axisControl.gridMinorTextField.target = self;
    axisControl.gridMinorTextField.action = @selector(updateGraphAxisData:);
    axisControl.gridMinorStepper.delegate = self;
  }//end for each axisControl
  self->axis1Control.gridMinorTextField.nextKeyView = self->axis2Control.minTextField;
  
  [self->axis1Control addObserver:self forKeyPath:CHAxisColorBinding options:0 context:0];
  [self->axis2Control addObserver:self forKeyPath:CHAxisColorBinding options:0 context:0];
  
  NSButton* inspectorLeftToolbarItemButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
  inspectorLeftToolbarItemButton.image = [NSImage imageNamed:@"inspector-left-off"];
  inspectorLeftToolbarItemButton.alternateImage = [NSImage imageNamed:@"inspector-left-on"];
  inspectorLeftToolbarItemButton.imagePosition = NSImageOnly;
  inspectorLeftToolbarItemButton.bordered = NO;
  inspectorLeftToolbarItemButton.buttonType = NSToggleButton;
  inspectorLeftToolbarItemButton.state = self->inspectorLeftView.hidden ? NSOffState : NSOnState;
  inspectorLeftToolbarItemButton.target = self;
  inspectorLeftToolbarItemButton.action = @selector(toolbarAction:);
  [[inspectorLeftToolbarItemButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
  self->inspectorLeftToolbarItem.view = inspectorLeftToolbarItemButton;
  
  NSButton* inspectorRightToolbarItemButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
  inspectorRightToolbarItemButton.image = [NSImage imageNamed:@"inspector-right-off"];
  inspectorRightToolbarItemButton.alternateImage = [NSImage imageNamed:@"inspector-right-on"];
  inspectorRightToolbarItemButton.imagePosition = NSImageOnly;
  inspectorRightToolbarItemButton.bordered = NO;
  inspectorRightToolbarItemButton.buttonType = NSToggleButton;
  inspectorRightToolbarItemButton.state = self->inspectorRightView.hidden ? NSOffState : NSOnState;
  inspectorRightToolbarItemButton.target = self;
  inspectorRightToolbarItemButton.action = @selector(toolbarAction:);
  [[inspectorRightToolbarItemButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
  self->inspectorRightToolbarItem.view = inspectorRightToolbarItemButton;
  
  self->inspectorLeftView.anchor = CHINSPECTOR_ANCHOR_LEFT;
  self->inspectorRightView.anchor = CHINSPECTOR_ANCHOR_RIGHT;
  self->inspectorLeftView.delegate = self;
  self->inspectorRightView.delegate = self;
  self->inspectorLeftView.visible = NO;
  [self inspectorVisibilityDidChange:nil];
  
  self->functionsTableView.arrayController = self->curvesController;
  [[self->functionsTableView tableColumnWithIdentifier:CHGraphCurveItemNameKey].headerCell setStringValue:NSLocalizedString(@"Function", @"")];
  self->functionsTableView.delegate = self;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:self->functionsTableView];
  [self->curvesController addObserver:self forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", NSEnabledBinding] options:0 context:0];
  [self->curvesController addObserver:self forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", CHGraphCurveItemCurveColorKey] options:0 context:0];
  [self->curvesController addObserver:self forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", CHGraphCurveItemPredicateColorFalseKey] options:0 context:0];
  [self->curvesController addObserver:self forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@", CHGraphCurveItemPredicateColorTrueKey] options:0 context:0];
  self->userVariableItemsTableView.arrayController = self->userVariableItemsController;
  [[self->userVariableItemsTableView tableColumnWithIdentifier:CHUserVariableItemNameKey].headerCell setStringValue:NSLocalizedString(@"Variable", @"")];
  [[self->userVariableItemsTableView tableColumnWithIdentifier:CHUserVariableItemEvaluatedValueAttributedStringKey].headerCell setStringValue:NSLocalizedString(@"Value", @"")];

  self->userVariableItemsTableView.delegate = self;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:NSTableViewSelectionDidChangeNotification object:self->userVariableItemsTableView];
  [self tableViewSelectionDidChange:nil];
  [self updateGraphAxisUI:nil];
  [self.windowForSheet makeFirstResponder:self->inputTextField];
  
  self->nibLoaded = YES;
}
//end windowControllerDidLoadNib:

-(BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
  BOOL result = [super validateMenuItem:menuItem];
  if (menuItem.action == @selector(saveDocument:))
    result = NO;
  else if (menuItem.action == @selector(saveDocumentAs:))
    result = NO;
  else if (menuItem.action == @selector(duplicateDocument:))
    result = NO;
  else if (menuItem.action == @selector(revertDocumentToSaved:))
    result = NO;
  else if (menuItem.action == @selector(renameDocument:))
    result = NO;
  else if (menuItem.action == @selector(moveDocument:))
    result = NO;
  else if (menuItem.action == @selector(runPageLayout:))
  {
    menuItem.title = NSLocalizedString(@"Page Setup...", @"");
    result = YES;
  }//end if (menuItem.action == @selector(runPageLayout:))
  else if (menuItem.action == @selector(printDocument:))
  {
    menuItem.title = NSLocalizedString(@"Print...", @"");
    result = YES;
  }//end if (menuItem.action == @selector(printDocument:))
  return result;
}
//end validateMenuItem:

-(IBAction) toolbarAction:(id)sender
{
  if (self->isAnimating)
    dispatch_after(.1, dispatch_get_main_queue(), ^{
      [self toolbarAction:sender];
    });
  else if ((sender == self->inspectorLeftToolbarItem)  || (sender == self->inspectorLeftToolbarItem.view))
    self->inspectorLeftView.visible = !self->inspectorLeftView.visible;
  else if ((sender == self->inspectorRightToolbarItem)  || (sender == self->inspectorRightToolbarItem.view))
    self->inspectorRightView.visible = !self->inspectorRightView.visible;
}
//end toolbarAction:

-(void) inspectorVisibilityDidChange:(NSNotification*)notification
{
  id sender = notification.object;
  BOOL isLeftSender = !sender || (sender == self->inspectorLeftView);
  BOOL isRightSender = !sender || (sender == self->inspectorRightView);
  BOOL isInspectorLeftViewHidden = self->inspectorLeftView.hidden;
  BOOL isInspectorRightViewHidden = self->inspectorRightView.hidden;
  BOOL nextInspectorLeftViewHidden  = isLeftSender ? !inspectorLeftView.visible : isInspectorLeftViewHidden;
  BOOL nextInspectorRightViewHidden = isRightSender ? !inspectorRightView.visible : isInspectorRightViewHidden;
  CGSize leftSize = nextInspectorLeftViewHidden ? CGSizeZero : [self->inspectorLeftView.subviews.firstObject frame].size;
  CGSize rightSize = nextInspectorRightViewHidden ? CGSizeZero : [self->inspectorRightView.subviews.firstObject frame].size;
  NSSize bottomSize = NSZeroSize;
  NSWindow* window = self.windowForSheet;
  NSSize centerMinSize = [window contentRectForFrameRect:NSMakeRect(0, 0, 240, 300+window.toolbarHeight)].size;
  NSSize contentMinSize = NSMakeSize(
    MAX(leftSize.width+centerMinSize.width+rightSize.width, bottomSize.width),
    MAX(MAX(leftSize.height, centerMinSize.height),rightSize.height));
  NSRect contentMinRect = NSMakeRect(0, 0, contentMinSize.width, contentMinSize.height);
  NSRect windowMinRect = [window frameRectForContentRect:contentMinRect];
  window.minSize = windowMinRect.size;

  CGRect nextWindowFrame = window.frame;
  nextWindowFrame.size.width = MAX(nextWindowFrame.size.width, windowMinRect.size.width);
  nextWindowFrame.size.height = MAX(nextWindowFrame.size.height, windowMinRect.size.height);
  CGRect nextContentFrame = [window contentRectForFrameRect:nextWindowFrame];
  [window setFrame:nextWindowFrame display:YES animate:YES];

  CGRect currCenterViewFrame     = NSRectToCGRect(self->centerView.frame);
  CGRect currInspectorLeftFrame  = NSRectToCGRect(self->inspectorLeftView.frame);
  CGRect currInspectorRightFrame = NSRectToCGRect(self->inspectorRightView.frame);
  CGRect nextCenterViewFrame     = currCenterViewFrame;
  CGRect nextInspectorLeftFrame  = currInspectorLeftFrame;
  CGRect nextInspectorRightFrame = currInspectorRightFrame;
  CGRect nextInspectorBottomFrame = CGRectMake(0, 0, nextContentFrame.size.width, 0);
  CGRect contentFrame =
    NSRectToCGRect(((NSView*)[window.contentView dynamicCastToClass:[NSView class]]).frame);

  if (!nextInspectorLeftViewHidden)
    nextInspectorLeftFrame.origin.x = 0;
  else//if (nextInspectorLeftViewHidden)
    nextInspectorLeftFrame.origin.x = -nextInspectorLeftFrame.size.width;

  if (!nextInspectorRightViewHidden)
    nextInspectorRightFrame.origin.x = nextContentFrame.size.width-nextInspectorRightFrame.size.width;
  else//if (nextInspectorRightViewHidden)
    nextInspectorRightFrame.origin.x = nextContentFrame.size.width;

  nextCenterViewFrame.origin.x = CGRectGetMaxX(nextInspectorLeftFrame);
  nextCenterViewFrame.size.width =
    CGRectGetMinX(nextInspectorRightFrame)-CGRectGetMaxX(nextInspectorLeftFrame);
  nextCenterViewFrame.origin.y = CGRectGetMaxY(nextInspectorBottomFrame);
  nextCenterViewFrame.size.height =
    contentFrame.size.height-CGRectGetMaxY(nextInspectorBottomFrame);
  nextInspectorLeftFrame.origin.y = CGRectGetMaxY(nextInspectorBottomFrame);
  nextInspectorLeftFrame.size.height =
    contentFrame.size.height-CGRectGetMaxY(nextInspectorBottomFrame);
  nextInspectorRightFrame.origin.y = CGRectGetMaxY(nextInspectorBottomFrame);
  nextInspectorRightFrame.size.height =
    contentFrame.size.height-CGRectGetMaxY(nextInspectorBottomFrame);

  if (!nextInspectorLeftViewHidden)
    self->inspectorLeftView.hidden = nextInspectorLeftViewHidden;
  if (!nextInspectorRightViewHidden)
    self->inspectorRightView.hidden = nextInspectorRightViewHidden;
  
  BOOL shouldAnimate = self->nibLoaded && (notification != nil);
  if (!shouldAnimate)
  {
    self->inspectorLeftView.hidden = nextInspectorLeftViewHidden;
    self->inspectorRightView.hidden = nextInspectorRightViewHidden;
    [self->inspectorLeftView setFrame:NSRectFromCGRect(nextInspectorLeftFrame)];
    [self->centerView setFrame:NSRectFromCGRect(nextCenterViewFrame)];
    [self->inspectorRightView setFrame:NSRectFromCGRect(nextInspectorRightFrame)];
  }//end if (!shouldAnimate)
  else//if (shouldAnimate)
  {
    self->isAnimating = YES;
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
      if (nextInspectorLeftViewHidden)
        self->inspectorLeftView.hidden = nextInspectorLeftViewHidden;
      if (nextInspectorRightViewHidden)
        self->inspectorRightView.hidden = nextInspectorRightViewHidden;
      self->isAnimating = NO;
    }];//end setCompletionHandler:
    [[NSAnimationContext currentContext] setDuration:0.5];
    [[self->inspectorLeftView animator] setFrame:NSRectFromCGRect(nextInspectorLeftFrame)];
    [[self->centerView animator] setFrame:NSRectFromCGRect(nextCenterViewFrame)];
    [[self->inspectorRightView animator] setFrame:NSRectFromCGRect(nextInspectorRightFrame)];
    [NSAnimationContext endGrouping];
  }//end if (shouldAnimate)
  
  [[self->inspectorLeftToolbarItem.view dynamicCastToClass:[NSButton class]] setState:nextInspectorLeftViewHidden ? NSOffState : NSOnState];
  [[self->inspectorRightToolbarItem.view dynamicCastToClass:[NSButton class]] setState:nextInspectorRightViewHidden ? NSOffState : NSOnState];
}
//end inspectorVisibilityDidChange:

-(void) setGraphFont:(NSFont*)value
{
  if (![value isEqualTo:self->graphFont])
  {
    [self->graphFont release];
    self->graphFont = [value copy];
    [self updateGraphData:NO];
  }//end if (![value isEqualTo:self->graphFont])
}
//end setGraphFont:

-(CHGraphCurve*) currentCurve
{
  CHGraphCurve* result = nil;
  NSArray* selectedObjects = [self->curvesController.arrangedObjects objectsAtIndexes:self->curvesController.selectionIndexes];
  CHGraphCurveItem* selectedCurve = [selectedObjects.lastObject dynamicCastToClass:[CHGraphCurveItem class]];
  result = selectedCurve.curve;
  if (!result)
    result = self->detachedCurve;
  return result;
}
//end currentCurve:

-(CHGraphCurveItem*) currentCurveItem
{
  CHGraphCurveItem* result = nil;
  NSArray* selectedObjects = [self->curvesController.arrangedObjects objectsAtIndexes:self->curvesController.selectionIndexes];
  CHGraphCurveItem* selectedCurve = [selectedObjects.lastObject dynamicCastToClass:[CHGraphCurveItem class]];
  result = selectedCurve;
  if (!result)
    result = self->detachedCurveItem;
  return result;
}
//end currentCurveItem:

-(CHUserVariableItem*) currentUserVariableItem
{
  CHUserVariableItem* result = nil;
  NSArray* selectedObjects = [self->userVariableItemsController.arrangedObjects objectsAtIndexes:self->userVariableItemsController.selectionIndexes];
  CHUserVariableItem* selectedUservariableItem = [selectedObjects.lastObject dynamicCastToClass:[CHUserVariableItem class]];
  result = selectedUservariableItem;
  return result;
}
//end currentUserVariableItem:

-(IBAction) addFunction:(id)sender
{
  if (sender == self->functionsAddButton)
  {
    NSString* input = [self->inputTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    CHGraphCurve* curve = [[CHGraphCurve alloc] initWithContext:self->chalkContext];
    curve.delegate = self;
    curve.elementPixelSize = 1;
    curve.input = input;
    CHGraphCurveItem* curveItem = [[self->detachedCurveItem copy] autorelease];
    curveItem.delegate = self;
    curveItem.enabled = YES;
    curveItem.name = input;
    curveItem.curve = curve;
    [curve release];
    [self->dependencyManager addItem:curveItem];
    [self->curvesController addObject:curveItem];
    [self->curvesController setSelectedObjects:@[curveItem]];
    self->detachedCurve.input = @"";
    [self->graphView addCurve:curveItem.curve];
  }//end if (sender == self->functionsAddButton)
}
//end addFunction:

-(IBAction) removeFunction:(id)sender
{
  if (sender == self->functionsRemoveButton)
  {
    __block BOOL hasDirtyCurve = NO;
    NSArray* selectedObjects = [self->curvesController.arrangedObjects objectsAtIndexes:self->curvesController.selectionIndexes];
    [selectedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHGraphCurveItem* curveItem = [obj dynamicCastToClass:[CHGraphCurveItem class]];
      if (curveItem)
      {
        hasDirtyCurve |= curveItem.enabled;
        [self->dependencyManager addItem:curveItem];
        [self->curvesController removeObject:curveItem];
        [self->graphView removeCurve:curveItem.curve];
        [[self->graphView cacheForCurve:curveItem.curve] invalidate];
      }//end if (curveItem)
    }];//end for each selected object
    if (hasDirtyCurve)
      [self updateGraphData:NO];
  }//end if (sender == self->functionsRemoveButton)
}
//end removeFunction:

-(IBAction) addUserVariableItem:(id)sender
{
  if (sender == self->userVariableItemsAddButton)
  {
    CHChalkIdentifierManager* identifierManager = self->chalkContext.identifierManager;
    NSString* unusedIdentifierName = [identifierManager unusedIdentifierNameWithTokenOption:YES];
    CHChalkIdentifier* identifier = !unusedIdentifierName ? nil :
      [[CHChalkIdentifierVariable alloc] initWithName:unusedIdentifierName caseSensitive:YES tokens:@[unusedIdentifierName] symbol:unusedIdentifierName symbolAsText:unusedIdentifierName symbolAsTeX:unusedIdentifierName];
    BOOL added = [identifierManager addIdentifier:identifier replace:NO preventTokenConflict:YES];
    [identifier release];//still retained by identifier manager on success
    if (!added)
      identifier = nil;
    CHUserVariableItem* userVariableItem = !identifier ? nil :
      [[[CHUserVariableItem alloc] initWithIdentifier:identifier isDynamic:NO input:nil evaluatedValue:nil context:self->chalkContext managedObjectContext:nil] autorelease];
    if (userVariableItem)
    {
      [userVariableItem setInput:@"0" parse:YES evaluate:YES];
      [self->dependencyManager addItem:userVariableItem];
      [self->userVariableItemsController addObject:userVariableItem];
      __block BOOL hasDirtyCurve = NO;
      __block BOOL hasDirtyUserVariableItem = NO;
      [[self->dependencyManager identifierDependentObjectsToUpdateFrom:@[userVariableItem]] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        hasDirtyCurve |= ([obj dynamicCastToClass:[CHGraphCurveItem class]] != nil);
        *stop |= hasDirtyCurve;
      }];//end for each dependency
      NSMutableArray* dirtyUserVariableItems = [NSMutableArray array];
      [self->dependencyManager.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
        if ([identifierDependent hasIdentifierDependencyByTokens:identifier.tokens])
        {
          [identifierDependent refreshIdentifierDependencies];
          CHGraphCurveItem* curveItem = [obj dynamicCastToClass:[CHGraphCurveItem class]];
          [[self->graphView cacheForCurve:curveItem.curve] invalidate];
          hasDirtyCurve |= (curveItem != nil);
          hasDirtyUserVariableItem |= [obj isKindOfClass:[CHUserVariableItem class]];
          [dirtyUserVariableItems safeAddObject:[obj dynamicCastToClass:[CHUserVariableItem class]]];
        }//end if ([curveItem hasIdentifierDependencyByTokens:identifier.tokens])
      }];//end for each curveItem
      if (hasDirtyCurve)
      {
        [self->functionsTableView setNeedsDisplay:YES];
        [self updateGraphData:NO];
      }//end if (hasDirtyCurve)
      if (hasDirtyUserVariableItem)
      {
        [dirtyUserVariableItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          [[obj dynamicCastToClass:[CHUserVariableItem class]] performEvaluation];
        }];//end for each dirtyUserVariableItem
        [self->userVariableItemsTableView setNeedsDisplay:YES];
      }//end if (hasDirtyUserVariableItem)
    }//end if (userVariableItem)
  }//end if (sender == self->userVariableItemsAddButton)
}
//end addUserVariableItem:

-(IBAction) removeUserVariableItem:(id)sender
{
  if (sender == self->userVariableItemsRemoveButton)
  {
    NSArray* selectedObjects = [self->userVariableItemsController.arrangedObjects objectsAtIndexes:self->userVariableItemsController.selectionIndexes];
    __block BOOL hasDirtyCurve = NO;
    NSArray* dirtyIdentifiers = [self->dependencyManager identifierDependentObjectsToUpdateFrom:selectedObjects];
    [selectedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHUserVariableItem* userVariableItem = [obj dynamicCastToClass:[CHUserVariableItem class]];
      if (userVariableItem)
      {
        [self->dependencyManager removeItem:userVariableItem];
        [self->userVariableItemsController removeObject:userVariableItem];
        [self->chalkContext.identifierManager removeIdentifier:userVariableItem.identifier];
      }//end if (userVariableItem)
    }];//end for each selected object
    [dirtyIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      id<CHChalkIdentifierDependent> identifierDependent = [obj dynamicCastToProtocol:@protocol(CHChalkIdentifierDependent)];
      [identifierDependent refreshIdentifierDependencies];
      CHGraphCurveItem* curveItem = [obj dynamicCastToClass:[CHGraphCurveItem class]];
      [[self->graphView cacheForCurve:curveItem.curve] invalidate];
      hasDirtyCurve |= (curveItem != nil);
    }];//end for each dependency
    [self->functionsTableView setNeedsDisplay:YES];
    [self->userVariableItemsTableView setNeedsDisplay:YES];
    if (hasDirtyCurve)
      [self updateGraphData:NO];
  }//end if (sender == self->userVariableItemsRemoveButton)
}
//end removeUserVariableItem:

-(IBAction) inputDidChange:(id)sender
{
  NSString* input = [self->inputTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  CHUserVariableItem* userVariableItem = self.currentUserVariableItem;
  __block BOOL shouldUpdateGraph = NO;
  if (userVariableItem)
  {
    [userVariableItem setInput:self->inputTextField.stringValue parse:YES evaluate:YES];
    [self->curvesController.arrangedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHGraphCurveItem* curveItem = [obj dynamicCastToClass:[CHGraphCurveItem class]];
      CHGraphCurve* curve = curveItem.curve;
      shouldUpdateGraph |= curveItem.enabled &&
        [curve.chalkParserNode isUsingIdentifier:userVariableItem.identifier identifierManager:curve.chalkContext.identifierManager];
      *stop |= shouldUpdateGraph;
    }];//end for each curveItem
    [self->dependencyManager updateCircularDependencies];
    [self->userVariableItemsTableView setNeedsDisplay:YES];
    NSArray* items = [self->dependencyManager identifierDependentObjectsToUpdateFrom:@[userVariableItem]];
    [items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHUserVariableItem* userVariableItem = [obj dynamicCastToClass:[CHUserVariableItem class]];
      CHGraphCurveItem* curveItem = [obj dynamicCastToClass:[CHGraphCurveItem class]];
      [[self->graphView cacheForCurve:curveItem.curve] invalidate];
      if (userVariableItem)
        [userVariableItem performEvaluation];
      shouldUpdateGraph |= curveItem.enabled;
    }];//end for each item
  }//end if (userVariableItem)
  else//if (!userVariableItem)
  {
    NSString* curveName = !input ? @"" : input;
    CHGraphCurveItem* curveItem = self.currentCurveItem;
    CHGraphCurve* curve = curveItem.curve;
    curveItem.name = curveName;
    if (![self->inputTextField.stringValue isEqualToString:curve.input])
    {
      curve.input = [self->inputTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      shouldUpdateGraph |= curve && (!curveItem || curveItem.enabled || (curveItem == self->detachedCurveItem));
      [[self->graphView cacheForCurve:curve] invalidate];
    }//end if (![self->inputTextField.stringValue isEqualToString:curve.input])
  }//end if (!userVariableItem)
  
  [self updateInputControls];

  if (shouldUpdateGraph)
    [self updateGraphData:NO];
}
//end inputDidChange:

-(IBAction) changeInputParameter:(id)sender
{
  if (sender == self->graphCurveParametersViewController)
  {
    [self updateInputControls];
  }//end if (sender == self->graphCurveParametersViewController)
}
//end changeInputParameter:

-(void) updateInputControls
{
  CHGraphCurve* curve = self.currentCurve;
  self->curveParametersButton.enabled = (curve != nil);
  self->graphCurveParametersViewController.graphCurveItem = self.currentCurveItem;

  NSMutableAttributedString* attributedString = [[[NSMutableAttributedString alloc] init] autorelease];

  CHChalkError* parseError = nil;
  NSString* input = nil;
  CHUserVariableItem* userVariableItem = self.currentUserVariableItem;
  if (userVariableItem)
  {
    input = userVariableItem.input;
    parseError = userVariableItem.parseError;
  }//end if (userVariableItem)
  else//if (!userVariableItem)
  {
    CHGraphCurve* currentCurve = self.currentCurve;
    input = currentCurve.input;
    parseError = currentCurve.parseError;
  }//end if (!userVariableItem)

  CHStreamWrapper* stream = [[CHStreamWrapper alloc] init];
  stream.attributedStringStream = attributedString;
  if ([NSString isNilOrEmpty:input]){
  }
  else if (!parseError)
    [stream writeString:input];
  else//if (parseError)
  {
    NSColor* errorColor = [NSColor colorWithCalibratedRed:253./255 green:177./255 blue:179./255 alpha:255./255];
    NSIndexSet* errorRanges = parseError.ranges;
    [errorRanges enumerateRangesWithin:input.range usingBlock:^(NSRange range, BOOL inside, BOOL *stop) {
      if (inside)
      {
        NSAttributedString* redString = [[NSAttributedString alloc] initWithString:[input substringWithRange:range] attributes:@{NSBackgroundColorAttributeName:errorColor}];
        [stream writeAttributedString:redString];
        [redString release];
      }//end if (inside)
      else if (!inside)
        [stream writeString:[input substringWithRange:range]];
    }];//end for each range
  }//end if (parseError)
  [stream release];
  self->inputTextField.attributedStringValue = attributedString;
}
//end updateInputControls

-(void) updateGraphData:(BOOL)invalidateCaches
{
  [self->chalkContext.computationConfiguration reset];
  [self->chalkContext invalidateCaches];
  self->chalkContext.computationConfiguration.computeMode = CHALK_COMPUTE_MODE_APPROX_INTERVALS;
  self->chalkContext.computationConfiguration.propagateNaN = NO;
  self->chalkContext.concurrentEvaluations = YES;
  [self->chalkContext.errorContext reset:nil];
  CHPreferencesController* preferencesController = [CHPreferencesController sharedPreferencesController];
  self->chalkContext.basePrefixesSuffixes = preferencesController.basePrefixesSuffixes;
  self->chalkContext.parseConfiguration.parseMode = preferencesController.parseMode;

  [self->curvesController.arrangedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    CHGraphCurveItem* curveItem = [obj dynamicCastToClass:[CHGraphCurveItem class]];
    curveItem.curve.visible = (curveItem.enabled && curveItem.curve && !curveItem.curve.parseError);
    if (invalidateCaches)
      [[self->graphView cacheForCurve:curveItem.curve] invalidate];
  }];//end for each curve
  if (self.currentCurve == self->detachedCurve)
  {
    NSString* input = self->detachedCurve.input;
    self->detachedCurve.visible = (![NSString isNilOrEmpty:input] && !self->detachedCurve.parseError);
    if (invalidateCaches)
      [[self->graphView cacheForCurve:self->detachedCurve] invalidate];
  }//end if (self.currentCurve == self->detachedCurve)
  [self->graphView setNeedsDisplay:YES];
}
//end updateGraphData:

-(BOOL) updateAutoMajorSteps
{
  BOOL result = NO;
  BOOL shouldUpdate = NO;
  if (self->graphView.graphContext.axisHorizontal1.majorStepAuto)
    shouldUpdate |= [self->graphView updateMajorStep:self->graphView.graphContext.axisHorizontal1 axisFlags:CHGRAPH_AXIS_ORIENTATION_HORIZONTAL];
  if (self->graphView.graphContext.axisVertical1.majorStepAuto)
    shouldUpdate |= [self->graphView updateMajorStep:self->graphView.graphContext.axisVertical1 axisFlags:CHGRAPH_AXIS_ORIENTATION_VERTICAL];
  if (shouldUpdate)
    [self updateGraphAxisUI:nil];
  result = shouldUpdate;
  return result;
}
//end updateAutoMajorSteps

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (object == self->axis1Control)
    [self updateGraphData:NO];
  else if (object == self->axis2Control)
    [self updateGraphData:NO];
  else if (object == self->curvesController)
  {
    NSString* subKeyPath = [[[keyPath captureComponentsMatchedByRegex:@"arrangedObjects\\.(.*)"] lastObject] dynamicCastToClass:[NSString class]];
    if ([subKeyPath isEqualToString:NSEnabledBinding])
      [self updateGraphData:NO];
    else if ([subKeyPath isEqualToString:CHGraphCurveItemCurveColorKey])
      [self updateGraphData:NO];
    else if ([subKeyPath isEqualToString:CHGraphCurveItemCurveInteriorColorKey])
      [self updateGraphData:NO];
    else if ([subKeyPath isEqualToString:CHGraphCurveItemPredicateColorFalseKey])
      [self updateGraphData:NO];
    else if ([subKeyPath isEqualToString:CHGraphCurveItemPredicateColorTrueKey])
      [self updateGraphData:NO];
  }//end if (object == self->curvesController)
}
//end observeValueForKeyPath:ofObject:change:context:

-(IBAction) centerAxes:(id)sender
{
  if ((sender == self->axis1Control.centerButton) || (sender == self->axis2Control.centerButton))
  {
    CHGraphScale* scale =
      (sender == self->axis1Control.centerButton) ? self->graphView.graphContext.axisHorizontal1.scale :
      (sender == self->axis2Control.centerButton) ? self->graphView.graphContext.axisVertical1.scale :
      nil;
    if (scale)
    {
      chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
      mpfi_ptr range = scale.computeRange;
      mpfr_srcptr diameter = scale.computeDiameter;
      mpfr_div_2exp(&range->right, diameter, 1, MPFR_RNDN);
      mpfr_neg(&range->left, &range->right, MPFR_RNDN);
      mpfi_revert_if_needed(range);
      chalkGmpFlagsRestore(oldFlags);
      [self updateGraphAxisUI:nil];
      [self updateGraphData:YES];
    }//end if (scale)
  }//end if (sender == self->axis1Control.centerButton)
}
//end centerAxes:

-(IBAction) updateGraphAxisData:(id)sender
{
   chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  __block BOOL shouldUpdateGraphData = NO;
  __block BOOL shouldUpdateGraphUI = NO;
  typedef enum {SIDE_LEFT, SIDE_RIGHT} side_t;
  BOOL (^mpfr_change)(mpfr_ptr, NSString*) = ^(mpfr_ptr dst, NSString* input) {
    BOOL result = NO;
    CHChalkValueNumberGmp* number = [self->chalkValueToStringTransformer reverseTransformedValue:input];
    const chalk_gmp_value_t* gmpNumberValue = !number ? 0 : number.valueConstReference;
    if (gmpNumberValue)
    {
      chalk_gmp_value_t gmpNumberValueMpfr = {0};
      chalkGmpValueSet(&gmpNumberValueMpfr, gmpNumberValue, self->chalkContext.gmpPool);
      mpfr_prec_t prec = self->chalkContext.computationConfiguration.softFloatSignificandBits;
      if (chalkGmpValueMakeRealExact(&gmpNumberValueMpfr, prec, self->chalkContext.gmpPool))
        mpfr_set(dst, gmpNumberValueMpfr.realExact, MPFR_RNDD);
      chalkGmpValueClear(&gmpNumberValueMpfr, YES, self->chalkContext.gmpPool);
    }//end if (gmpNumberValue)
    return result;
  };//end mpfr_change
  BOOL (^scale_range_change)(CHGraphScale*, side_t, NSString*) = ^(CHGraphScale* scale, side_t side, NSString* input) {
    BOOL result = NO;
    mpfi_ptr range = scale.computeRange;
    CHChalkValueNumberGmp* number = [self->chalkValueToStringTransformer reverseTransformedValue:input];
    const chalk_gmp_value_t* gmpNumberValue = !number ? 0 : number.valueConstReference;
    if (gmpNumberValue)
    {
      chalk_gmp_value_t gmpNumberValueMpfr = {0};
      chalkGmpValueSet(&gmpNumberValueMpfr, gmpNumberValue, self->chalkContext.gmpPool);
      mpfr_prec_t prec = self->chalkContext.computationConfiguration.softFloatSignificandBits;
      if (chalkGmpValueMakeRealExact(&gmpNumberValueMpfr, prec, self->chalkContext.gmpPool))
      {
        mpfi_t tmp;
        mpfi_init_set(tmp, range);
        if (side == SIDE_LEFT)
        {
          mpfr_set(&range->left, gmpNumberValueMpfr.realExact, MPFR_RNDD);
          mpfr_max(&range->right, &range->left, &range->right, MPFR_RNDN);
          [scale updateData];
        }//end if (side == SIDE_LEFT)
        else if (side == SIDE_RIGHT)
        {
          mpfr_set(&range->right, gmpNumberValueMpfr.realExact, MPFR_RNDU);
          mpfr_min(&range->left, &range->left, &range->right, MPFR_RNDN);
          [scale updateData];
        }//end if (side == SIDE_RIGHT)
        result = !mpfr_equal_p(&tmp->left, &range->left) || !mpfr_equal_p(&tmp->right, &range->right);
        mpfi_clear(tmp);
      }//end if (chalkGmpValueMakeRealExact(&gmpNumberValueMpfr, prec, self->chalkContext.gmpPool))
      chalkGmpValueClear(&gmpNumberValueMpfr, YES, self->chalkContext.gmpPool);
    }//end if (gmpNumberValue)
    return result;
  };//end scale_range_change
  if (!sender || (sender == self->axis1Control.minTextField))
    shouldUpdateGraphData |= scale_range_change(self->graphView.graphContext.axisHorizontal1.scale, SIDE_LEFT, self->axis1Control.minTextField.stringValue);
  if (!sender || (sender == self->axis1Control.maxTextField))
    shouldUpdateGraphData |= scale_range_change(self->graphView.graphContext.axisHorizontal1.scale, SIDE_RIGHT, self->axis1Control.maxTextField.stringValue);
  if (!sender || (sender == self->axis2Control.minTextField))
    shouldUpdateGraphData |= scale_range_change(self->graphView.graphContext.axisVertical1.scale, SIDE_LEFT, self->axis2Control.minTextField.stringValue);
  if (!sender || (sender == self->axis2Control.maxTextField))
    shouldUpdateGraphData |= scale_range_change(self->graphView.graphContext.axisVertical1.scale, SIDE_RIGHT, self->axis2Control.maxTextField.stringValue);
  if (!sender || (sender == self->axis1Control.scaleTypeButton))
  {
    self->graphView.graphContext.axisHorizontal1.scale.scaleType = (chgraph_scale_t)self->axis1Control.scaleTypeButton.selectedTag;
    shouldUpdateGraphData = YES;
    shouldUpdateGraphUI = YES;
  }//end if (!sender || (sender == self->axis1Control.scaleTypeButton))
  if (!sender || (sender == self->axis2Control.scaleTypeButton))
  {
    self->graphView.graphContext.axisVertical1.scale.scaleType = (chgraph_scale_t)self->axis2Control.scaleTypeButton.selectedTag;
    shouldUpdateGraphData = YES;
    shouldUpdateGraphUI = YES;
  }//end if (!sender || (sender == self->axis2Control.scaleTypeButton))
  if (!sender || (sender == self->axis1Control.scaleTypeBaseTextField))
  {
    self->graphView.graphContext.axisHorizontal1.scale.logarithmicBase = (int)self->axis1Control.scaleTypeBaseTextField.integerValue;
    shouldUpdateGraphData = YES;
    shouldUpdateGraphUI = YES;
  }//end if (!sender || (sender == self->axis1Control.scaleTypeBaseTextField))
  if (!sender || (sender == self->axis2Control.scaleTypeBaseTextField))
  {
    self->graphView.graphContext.axisVertical1.scale.logarithmicBase = (int)self->axis2Control.scaleTypeBaseTextField.integerValue;
    shouldUpdateGraphData = YES;
    shouldUpdateGraphUI = YES;
  }//end if (!sender || (sender == self->axis2Control.scaleTypeBaseTextField))
  if (!sender || (sender == self->axis1Control.gridMajorAutoCheckBox))
  {
    self->graphView.graphContext.axisHorizontal1.majorStepAuto = (self->axis1Control.gridMajorAutoCheckBox.state == NSOnState);
    shouldUpdateGraphUI |= ![self updateAutoMajorSteps];
  }//end if (!sender || (sender == self->axis1Control.gridMajorAutoCheckBox))
  if (!sender || (sender == self->axis2Control.gridMajorAutoCheckBox))
  {
    self->graphView.graphContext.axisVertical1.majorStepAuto = (self->axis2Control.gridMajorAutoCheckBox.state == NSOnState);
    shouldUpdateGraphUI |= ![self updateAutoMajorSteps];
  }//end if (!sender || (sender == self->axis2Control.gridMajorAutoCheckBox))
  if (!sender || (sender == self->axis1Control.gridMajorTextField))
  {
    NSString* input = [self->axis1Control.gridMajorTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([NSString isNilOrEmpty:input])
      mpfr_set_nan(self->graphView.graphContext.axisHorizontal1.majorStep);
    else//if (![NSString isNilOrEmpty:input])
    {
      mpfr_change(self->graphView.graphContext.axisHorizontal1.majorStep, input);
      if (mpfr_sgn(self->graphView.graphContext.axisHorizontal1.majorStep) < 0)
        mpfr_set_zero(self->graphView.graphContext.axisHorizontal1.majorStep, 0);
    }//end if (![NSString isNilOrEmpty:input])
    shouldUpdateGraphData = YES;
    shouldUpdateGraphUI = YES;
  }//end if (!sender || (sender == self->axis1Control.gridMajorTextField))
  if (!sender || (sender == self->axis1Control.gridMinorTextField))
  {
    NSString* input = [self->axis1Control.gridMinorTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([NSString isNilOrEmpty:input])
      self->graphView.graphContext.axisHorizontal1.minorDivisions = 0;
    else//if (![NSString isNilOrEmpty:input])
      self->graphView.graphContext.axisHorizontal1.minorDivisions = MAX(0, input.integerValue);
    shouldUpdateGraphData = YES;
    shouldUpdateGraphUI = YES;
  }//end if (!sender || (sender == self->axis1Control.gridMinorTextField))
  if (!sender || (sender == self->axis2Control.gridMajorTextField))
  {
    NSString* input = [self->axis2Control.gridMajorTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([NSString isNilOrEmpty:input])
      mpfr_set_nan(self->graphView.graphContext.axisVertical1.majorStep);
    else//if (![NSString isNilOrEmpty:input])
    {
      mpfr_change(self->graphView.graphContext.axisVertical1.majorStep, input);
      if (mpfr_sgn(self->graphView.graphContext.axisVertical1.majorStep) < 0)
        mpfr_set_zero(self->graphView.graphContext.axisVertical1.majorStep, 0);
    }//end if (![NSString isNilOrEmpty:input])
    shouldUpdateGraphData = YES;
    shouldUpdateGraphUI = YES;
  }//end if (!sender || (sender == self->axis2Control.gridMajorTextField))
  if (!sender || (sender == self->axis2Control.gridMinorTextField))
  {
    NSString* input = [self->axis2Control.gridMinorTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([NSString isNilOrEmpty:input])
      self->graphView.graphContext.axisVertical1.minorDivisions = 0;
    else//if (![NSString isNilOrEmpty:input])
      self->graphView.graphContext.axisVertical1.minorDivisions = MAX(0, input.integerValue);
    shouldUpdateGraphData = YES;
    shouldUpdateGraphUI = YES;
  }//end if (!sender || (sender == self->axis2Control.gridMinorTextField))
  if (shouldUpdateGraphUI)
    [self updateGraphAxisUI:nil];
  if (shouldUpdateGraphData)
    [self updateGraphData:YES];
  chalkGmpFlagsRestore(oldFlags);
}
//end updateGraphAxisData:

-(void) updateGraphAxisUI:(id)target
{
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  void (^change_from_mpfr)(mpfr_srcptr, NSTextField*) = ^(mpfr_srcptr value, NSTextField* textField) {
    chalk_gmp_value_t gmpValue = {0};
    mpfr_prec_t prec = self->chalkContext.computationConfiguration.softFloatSignificandBits;
    if (chalkGmpValueMakeRealExact(&gmpValue, prec, self->chalkContext.gmpPool))
    {
      mpfr_set(gmpValue.realExact, value, MPFR_RNDN);
      CHChalkValueNumberGmp* number = [[CHChalkValueNumberGmp alloc] initWithToken:[CHChalkToken chalkTokenEmpty] value:&gmpValue naturalBase:self->chalkContext.computationConfiguration.baseDefault context:self->chalkContext];
      NSString* string = [self->chalkValueToStringTransformer transformedValue:number];
      [number release];
      textField.stringValue = string;
    }//end if (chalkGmpValueMakeRealApprox(&gmpValue, prec, self->chalkContext.gmpPool))
    chalkGmpValueClear(&gmpValue, YES, self->chalkContext.gmpPool);
  };//end change_from_mpfr
  if (!target || (target == self->axis1Control.minTextField))
    change_from_mpfr(&self->graphView.graphContext.axisHorizontal1.scale.computeRange->left, self->axis1Control.minTextField);
  if (!target || (target == self->axis1Control.maxTextField))
    change_from_mpfr(&self->graphView.graphContext.axisHorizontal1.scale.computeRange->right, self->axis1Control.maxTextField);
  if (!target || (target == self->axis2Control.minTextField))
    change_from_mpfr(&self->graphView.graphContext.axisVertical1.scale.computeRange->left, self->axis2Control.minTextField);
  if (!target || (target == self->axis2Control.maxTextField))
    change_from_mpfr(&self->graphView.graphContext.axisVertical1.scale.computeRange->right, self->axis2Control.maxTextField);
  if (!target || (target == self->axis1Control.scaleTypeButton))
  {
    chgraph_scale_t scaleType = self->graphView.graphContext.axisHorizontal1.scale.scaleType;
    [self->axis1Control.scaleTypeButton selectItemWithTag:(NSInteger)scaleType];
    self->axis1Control.scaleTypeBaseTextField.enabled = (scaleType == CHGRAPH_SCALE_LOGARITHMIC);
    self->axis1Control.scaleTypeBaseStepper.enabled = (scaleType == CHGRAPH_SCALE_LOGARITHMIC);
  }//end if (!target || (target == self->axis1Control.scaleTypeButton))
  if (!target || (target == self->axis2Control.scaleTypeButton))
  {
    chgraph_scale_t scaleType = self->graphView.graphContext.axisVertical1.scale.scaleType;
    [self->axis2Control.scaleTypeButton selectItemWithTag:(NSInteger)self->graphView.graphContext.axisVertical1.scale.scaleType];
    [self->axis2Control.scaleTypeButton selectItemWithTag:(NSInteger)scaleType];
    self->axis2Control.scaleTypeBaseTextField.enabled = (scaleType == CHGRAPH_SCALE_LOGARITHMIC);
    self->axis2Control.scaleTypeBaseStepper.enabled = (scaleType == CHGRAPH_SCALE_LOGARITHMIC);
  }//end if (!target || (target == self->axis2Control.scaleTypeButton))
  if (!target || (target == self->axis1Control.scaleTypeBaseTextField))
  {
    chgraph_scale_t scaleType = self->graphView.graphContext.axisHorizontal1.scale.scaleType;
    self->axis1Control.scaleTypeBaseTextField.stringValue =
      (scaleType == CHGRAPH_SCALE_LOGARITHMIC) ? @(self->graphView.graphContext.axisHorizontal1.scale.logarithmicBase).stringValue :
      NSLocalizedString(@"n/a", @"");
  }//end if (!target || (target == self->axis1Control.scaleTypeBaseTextField))
  if (!target || (target == self->axis2Control.scaleTypeBaseTextField))
  {
    chgraph_scale_t scaleType = self->graphView.graphContext.axisVertical1.scale.scaleType;
    self->axis2Control.scaleTypeBaseTextField.stringValue =
      (scaleType == CHGRAPH_SCALE_LOGARITHMIC) ? @(self->graphView.graphContext.axisVertical1.scale.logarithmicBase).stringValue :
      NSLocalizedString(@"n/a", @"");
  }//end if (!target || (target == self->axis2Control.scaleTypeBaseTextField))
  if (!target || (target == self->axis1Control.gridMajorAutoCheckBox))
  {
    self->axis1Control.gridMajorAutoCheckBox.state = (self->graphView.graphContext.axisHorizontal1.majorStepAuto ? NSOnState : NSOffState);
    self->axis1Control.gridMajorTextField.enabled = !self->graphView.graphContext.axisHorizontal1.majorStepAuto;
    self->axis1Control.gridMajorStepper.enabled = !self->graphView.graphContext.axisHorizontal1.majorStepAuto;
  }//end if (!target || (target == self->axis1Control.gridMajorAutoCheckBox))
  if (!target || (target == self->axis2Control.gridMajorAutoCheckBox))
  {
    self->axis2Control.gridMajorAutoCheckBox.state = (self->graphView.graphContext.axisVertical1.majorStepAuto ? NSOnState : NSOffState);
    self->axis2Control.gridMajorTextField.enabled = !self->graphView.graphContext.axisVertical1.majorStepAuto;
    self->axis2Control.gridMajorStepper.enabled = !self->graphView.graphContext.axisVertical1.majorStepAuto;
  }//end if (!target || (target == self->axis2Control.gridMajorAutoCheckBox))
  if (!target || (target == self->axis1Control.gridMajorTextField))
  {
    if (!mpfr_regular_p(self->graphView.graphContext.axisHorizontal1.majorStep) || (mpfr_sgn(self->graphView.graphContext.axisHorizontal1.majorStep)<=0))
      self->axis1Control.gridMajorTextField.stringValue = @"";
    else
      change_from_mpfr(self->graphView.graphContext.axisHorizontal1.majorStep, self->axis1Control.gridMajorTextField);
  }//end if (!target || (target == self->axis1Control.gridMajorTextField))
  if (!target || (target == self->axis1Control.gridMinorTextField))
  {
    if (!self->graphView.graphContext.axisHorizontal1.minorDivisions)
      self->axis1Control.gridMinorTextField.stringValue = @"";
    else
      self->axis1Control.gridMinorTextField.integerValue = self->graphView.graphContext.axisHorizontal1.minorDivisions;
  }//end if (!target || (target == self->axis1Control.gridMinorTextField))
  if (!target || (target == self->axis2Control.gridMajorTextField))
  {
    if (!mpfr_regular_p(self->graphView.graphContext.axisVertical1.majorStep) || (mpfr_sgn(self->graphView.graphContext.axisVertical1.majorStep)<=0))
      self->axis2Control.gridMajorTextField.stringValue = @"";
    else
      change_from_mpfr(self->graphView.graphContext.axisVertical1.majorStep, self->axis2Control.gridMajorTextField);
  }//end if (!target || (target == self->axis2Control.gridMajorTextField))
  if (!target || (target == self->axis2Control.gridMinorTextField))
  {
    if (!self->graphView.graphContext.axisVertical1.minorDivisions)
      self->axis2Control.gridMinorTextField.stringValue = @"";
    else
      self->axis2Control.gridMinorTextField.integerValue = self->graphView.graphContext.axisVertical1.minorDivisions;
  }//end if (!target || (target == self->axis2Control.gridMinorTextField))
  chalkGmpFlagsRestore(oldFlags);
}
//end updateGraphAxisUI:

-(IBAction) makeSnapshot:(id)sender
{
  NSMenuItem* senderAsMenuItem = [sender dynamicCastToClass:[NSMenuItem class]];
  if (senderAsMenuItem && [self->graphSnapshotPopUpButton.menu.itemArray containsObject:senderAsMenuItem])
  {
    chalk_export_format_t exportType =
      (senderAsMenuItem.tag == 1) ? CHALK_EXPORT_FORMAT_PDF :
      (senderAsMenuItem.tag == 2) ? CHALK_EXPORT_FORMAT_PNG :
      (senderAsMenuItem.tag == 3) ? CHALK_EXPORT_FORMAT_PDF :
      (senderAsMenuItem.tag == 4) ? CHALK_EXPORT_FORMAT_PNG :
      CHALK_EXPORT_FORMAT_UNDEFINED;
    BOOL feedPasteboard =
      (senderAsMenuItem.tag == 1) ||
      (senderAsMenuItem.tag == 2);
    BOOL createFile =
      (senderAsMenuItem.tag == 3) ||
      (senderAsMenuItem.tag == 4);
    if (exportType != CHALK_EXPORT_FORMAT_UNDEFINED)
    {
      NSMutableData* targetData = [NSMutableData data];
      CGDataConsumerRef pdfDataConsumer = (exportType == CHALK_EXPORT_FORMAT_PDF) ? CGDataConsumerCreateWithCFData((CFMutableDataRef)targetData) : 0;
      
      NSRect bounds = self->graphView.bounds;
      NSRect boundsBackingRect = [self->graphView convertRectToBacking:bounds];

      CGRect mediaBox = NSRectToCGRect(boundsBackingRect);
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      CGContextRef cgContext =
        (exportType == CHALK_EXPORT_FORMAT_PNG) ?
          CGBitmapContextCreate(0, boundsBackingRect.size.width, boundsBackingRect.size.height, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast) :
        (exportType == CHALK_EXPORT_FORMAT_PDF) && pdfDataConsumer ?
          CGPDFContextCreate(pdfDataConsumer, &mediaBox, 0) :
        0;
      if (pdfDataConsumer)
        CGPDFContextBeginPage(cgContext, 0);
      
      CGContextSaveGState(cgContext);
      CGContextScaleCTM(cgContext,
        !boundsBackingRect.size.width ? 1 : bounds.size.width/boundsBackingRect.size.width,
        !boundsBackingRect.size.height ? 1 : bounds.size.height/boundsBackingRect.size.height);
      [self->graphView renderInContext:cgContext bounds:boundsBackingRect drawAxes:YES drawMajorGrid:YES drawMinorGrid:YES drawMajorValues:YES drawDataCursors:NO mouseLocation:CGPointZero];
      CGContextRestoreGState(cgContext);
      
      CGImageRef image = (exportType == CHALK_EXPORT_FORMAT_PNG) ? CGBitmapContextCreateImage(cgContext) : 0;
      CGContextFlush(cgContext);
      if (pdfDataConsumer)
      {
        CGPDFContextEndPage(cgContext);
        CGPDFContextClose(cgContext);
      }//end if (pdfDataConsumer)
      CGContextRelease(cgContext);
      CGDataConsumerRelease(pdfDataConsumer);
      CGColorSpaceRelease(colorSpace);
      if (image)
      {
        CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((CFMutableDataRef)targetData,
          (exportType == CHALK_EXPORT_FORMAT_PNG) ? kUTTypePNG :
          0,
          1, 0);
        if (imageDestination && image)
          CGImageDestinationAddImage(imageDestination, image, 0);
        if (imageDestination)
        {
          CGImageDestinationFinalize(imageDestination);
          CFRelease(imageDestination);
        }//end if (imageDestination)
        CGImageRelease(image);
      }//end if (image)
      if (feedPasteboard)
      {
        NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
        NSString* pasteboardType =
          (exportType == CHALK_EXPORT_FORMAT_PDF) ? (NSString*)kUTTypePDF :
          (exportType == CHALK_EXPORT_FORMAT_PNG) ? (NSString*)kUTTypePNG :
          nil;
        if (pasteboardType)
        {
          [pasteboard declareTypes:@[pasteboardType] owner:nil];
          [pasteboard setData:targetData forType:pasteboardType];
        }//end if (pasteboardType)
      }//end if (feedPasteboard)
      if (createFile)
      {
        NSFileManager* fileManager = [NSFileManager defaultManager];
        NSString* folder = [[NSWorkspace sharedWorkspace] getBestStandardPath:NSDesktopDirectory domain:NSUserDomainMask defaultValue:nil];
        NSString* name = NSLocalizedString(@"Untitled", @"");
        NSUInteger suffixIndex = 0;
        NSString* extension =
          (exportType == CHALK_EXPORT_FORMAT_PNG) ? @"png" :
          (exportType == CHALK_EXPORT_FORMAT_PDF) ? @"pdf" :
          @"";
        NSString* filePath = nil;
        BOOL filePathOK = NO;
        while(!filePathOK)
        {
          NSString* suffix = !suffixIndex ? @"" : [NSString stringWithFormat:@" %@", @(suffixIndex)];
          NSString* fileName = [NSString stringWithFormat:@"%@%@.%@", name, suffix, extension];
          filePath = !folder ? nil : [folder stringByAppendingPathComponent:fileName];
          BOOL isDirectory = NO;
          filePathOK = ![fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
          if (!filePathOK)
            ++suffixIndex;
        }//end while(!filePathOK)
        NSURL* url = !filePath ? nil : [NSURL fileURLWithPath:filePath];
        if (url)
          [targetData writeToURL:url atomically:YES];
      }//end if (createFile)
    }//end if (exportType != CHALK_EXPORT_FORMAT_UNDEFINED)
  }//end if (senderAsMenuItem && [self->graphSnapshotPopUpButton.menu.itemArray containsObject:senderAsMenuItem])
}
//end makeSnapshot:

-(IBAction) changeGraphAction:(id)sender
{
  if (sender == self->graphActionSegmentedControl)
    self->graphView.currentAction = (chgraph_action_t)self->graphActionSegmentedControl.selectedSegmentTag;
}
//end changeGraphAction:

-(CHGraphCurveItem*) curveItemForCurve:(CHGraphCurve*)curve
{
  __block CHGraphCurveItem* result = nil;
  if (curve == self->detachedCurve)
    result = self->detachedCurveItem;
  else
    [self->curvesController.arrangedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      CHGraphCurveItem* curveItem = [obj dynamicCastToClass:[CHGraphCurveItem class]];
      CHGraphCurve* graphCurve = curveItem.curve;
      if (graphCurve == curve)
        result = curveItem;
      if (result)
        *stop = YES;
    }];//end for each curveItem
  return result;
}
//end curveItemForCurve:

#pragma mark CHStepperDelegate

-(BOOL) stepperShouldIncrement:(CHStepper*)stepper
{
  BOOL result = NO;
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (stepper == self->axis1Control.minStepper)
  {
    CHGraphScale* scale = self->graphView.graphContext.axisHorizontal1.scale;
    mpfi_ptr computeRange = scale.computeRange;
    mpfr_add_si(&computeRange->left, &computeRange->left, 1, MPFR_RNDN);
    mpfr_max(&computeRange->right, &computeRange->left, &computeRange->right, MPFR_RNDN);
    [scale updateData];
    [self updateGraphAxisUI:self->axis1Control.minTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.minStepper)
  else if (stepper == self->axis1Control.maxStepper)
  {
    CHGraphScale* scale = self->graphView.graphContext.axisHorizontal1.scale;
    mpfi_ptr computeRange = scale.computeRange;
    mpfr_add_si(&computeRange->right, &computeRange->right, 1, MPFR_RNDN);
    [scale updateData];
    [self updateGraphAxisUI:self->axis1Control.maxTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.maxStepper)
  else if (stepper == self->axis2Control.minStepper)
  {
    CHGraphScale* scale = self->graphView.graphContext.axisVertical1.scale;
    mpfi_ptr computeRange = scale.computeRange;
    mpfr_add_si(&computeRange->left, &computeRange->left, 1, MPFR_RNDN);
    mpfr_max(&computeRange->right, &computeRange->left, &computeRange->right, MPFR_RNDN);
    [scale updateData];
    [self updateGraphAxisUI:self->axis2Control.minTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.minStepper)
  else if (stepper == self->axis2Control.maxStepper)
  {
    CHGraphScale* scale = self->graphView.graphContext.axisVertical1.scale;
    mpfi_ptr computeRange = scale.computeRange;
    mpfr_add_si(&computeRange->right, &computeRange->right, 1, MPFR_RNDN);
    [scale updateData];
    [self updateGraphAxisUI:self->axis2Control.maxTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.maxStepper)
  else if (stepper == self->axis1Control.scaleTypeBaseStepper)
  {
    self->graphView.graphContext.axisHorizontal1.scale.logarithmicBase = chalkGmpBaseMakeValid(self->graphView.graphContext.axisHorizontal1.scale.logarithmicBase+1);
    [self updateGraphAxisUI:self->axis1Control.scaleTypeBaseTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.scaleTypeBaseStepper)
  else if (stepper == self->axis2Control.scaleTypeBaseStepper)
  {
    self->graphView.graphContext.axisVertical1.scale.logarithmicBase = chalkGmpBaseMakeValid(self->graphView.graphContext.axisVertical1.scale.logarithmicBase+1);
    [self updateGraphAxisUI:self->axis2Control.scaleTypeBaseTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.scaleTypeBaseStepper)
  else if (stepper == self->axis1Control.gridMajorStepper)
  {
    mpfr_add_si(self->graphView.graphContext.axisHorizontal1.majorStep, self->graphView.graphContext.axisHorizontal1.majorStep, 1, MPFR_RNDN);
    [self updateGraphAxisUI:self->axis1Control.gridMajorTextField];
    [self->graphView setNeedsDisplay:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.gridMajorStepper)
  else if (stepper == self->axis1Control.gridMinorStepper)
  {
    if (self->graphView.graphContext.axisHorizontal1.minorDivisions < NSUIntegerMax)
      self->graphView.graphContext.axisHorizontal1.minorDivisions =
        self->graphView.graphContext.axisHorizontal1.minorDivisions+1;
    [self updateGraphAxisUI:self->axis1Control.gridMinorTextField];
    [self->graphView setNeedsDisplay:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.gridMinorStepper)
   else if (stepper == self->axis2Control.gridMajorStepper)
  {
    mpfr_add_si(self->graphView.graphContext.axisVertical1.majorStep, self->graphView.graphContext.axisVertical1.majorStep, 1, MPFR_RNDN);
    [self updateGraphAxisUI:self->axis2Control.gridMajorTextField];
    [self->graphView setNeedsDisplay:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.gridMajorStepper)
  else if (stepper == self->axis2Control.gridMinorStepper)
  {
    if (self->graphView.graphContext.axisVertical1.minorDivisions < NSUIntegerMax)
      self->graphView.graphContext.axisVertical1.minorDivisions =
        self->graphView.graphContext.axisVertical1.minorDivisions+1;
    [self updateGraphAxisUI:self->axis2Control.gridMinorTextField];
    [self->graphView setNeedsDisplay:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.gridMinorStepper)
  chalkGmpFlagsRestore(oldFlags);
  return result;
}
//end stepperShouldIncrement:

-(BOOL) stepperShouldDecrement:(CHStepper*)stepper
{
  BOOL result = NO;
  chalk_compute_flags_t oldFlags = chalkGmpFlagsSave(NO);
  if (stepper == self->axis1Control.minStepper)
  {
    CHGraphScale* scale = self->graphView.graphContext.axisHorizontal1.scale;
    mpfi_ptr computeRange = scale.computeRange;
    mpfr_sub_si(&computeRange->left, &computeRange->left, 1, MPFR_RNDN);
    [scale updateData];
    [self updateGraphAxisUI:self->axis1Control.minTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.minStepper)
  else if (stepper == self->axis1Control.maxStepper)
  {
    CHGraphScale* scale = self->graphView.graphContext.axisHorizontal1.scale;
    mpfi_ptr computeRange = scale.computeRange;
    mpfr_sub_si(&computeRange->right, &computeRange->right, 1, MPFR_RNDN);
    mpfr_min(&computeRange->left, &computeRange->left, &computeRange->right, MPFR_RNDN);
    [scale updateData];
    [self updateGraphAxisUI:self->axis1Control.maxTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.maxStepper)
  else if (stepper == self->axis2Control.minStepper)
  {
    CHGraphScale* scale = self->graphView.graphContext.axisVertical1.scale;
    mpfi_ptr computeRange = scale.computeRange;
    mpfr_sub_si(&computeRange->left, &computeRange->left, 1, MPFR_RNDN);
    [scale updateData];
    [self updateGraphAxisUI:self->axis2Control.minTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.minStepper)
  else if (stepper == self->axis2Control.maxStepper)
  {
    CHGraphScale* scale = self->graphView.graphContext.axisVertical1.scale;
    mpfi_ptr computeRange = scale.computeRange;
    mpfr_sub_si(&computeRange->right, &computeRange->right, 1, MPFR_RNDN);
    mpfr_min(&computeRange->left, &computeRange->left, &computeRange->right, MPFR_RNDN);
    [scale updateData];
    [self updateGraphAxisUI:self->axis2Control.maxTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.maxStepper)
  else if (stepper == self->axis1Control.scaleTypeBaseStepper)
  {
    self->graphView.graphContext.axisHorizontal1.scale.logarithmicBase = chalkGmpBaseMakeValid(self->graphView.graphContext.axisHorizontal1.scale.logarithmicBase-1);
    [self updateGraphAxisUI:self->axis1Control.scaleTypeBaseTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.scaleTypeBaseStepper)
  else if (stepper == self->axis2Control.scaleTypeBaseStepper)
  {
    self->graphView.graphContext.axisVertical1.scale.logarithmicBase = chalkGmpBaseMakeValid(self->graphView.graphContext.axisVertical1.scale.logarithmicBase-1);
    [self updateGraphAxisUI:self->axis2Control.scaleTypeBaseTextField];
    [self updateGraphData:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.scaleTypeBaseStepper)
  else if (stepper == self->axis1Control.gridMajorStepper)
  {
    mpfr_sub_si(self->graphView.graphContext.axisHorizontal1.majorStep, self->graphView.graphContext.axisHorizontal1.majorStep, 1, MPFR_RNDN);
    mpfr_t zero;
    mpfr_init_set_si(zero, 0, MPFR_RNDN);
    mpfr_max(self->graphView.graphContext.axisHorizontal1.majorStep, self->graphView.graphContext.axisHorizontal1.majorStep, zero, MPFR_RNDN);
    mpfr_clear(zero);
    [self updateGraphAxisUI:self->axis1Control.gridMajorTextField];
    [self->graphView setNeedsDisplay:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.gridMajorStepper)
  else if (stepper == self->axis1Control.gridMinorStepper)
  {
    if (self->graphView.graphContext.axisHorizontal1.minorDivisions)
      self->graphView.graphContext.axisHorizontal1.minorDivisions =
        self->graphView.graphContext.axisHorizontal1.minorDivisions-1;
    [self updateGraphAxisUI:self->axis1Control.gridMinorTextField];
    [self->graphView setNeedsDisplay:YES];
    result = YES;
  }//end if (stepper == self->axis1Control.gridMinorStepper)
   else if (stepper == self->axis2Control.gridMajorStepper)
  {
    mpfr_t zero;
    mpfr_init_set_si(zero, 0, MPFR_RNDN);
    mpfr_sub_si(self->graphView.graphContext.axisVertical1.majorStep, self->graphView.graphContext.axisVertical1.majorStep, 1, MPFR_RNDN);
    mpfr_max(self->graphView.graphContext.axisVertical1.majorStep, self->graphView.graphContext.axisVertical1.majorStep, zero, MPFR_RNDN);
    mpfr_clear(zero);
    [self updateGraphAxisUI:self->axis2Control.gridMajorTextField];
    [self->graphView setNeedsDisplay:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.gridMajorStepper)
  else if (stepper == self->axis2Control.gridMinorStepper)
  {
    if (self->graphView.graphContext.axisVertical1.minorDivisions)
      self->graphView.graphContext.axisVertical1.minorDivisions =
        self->graphView.graphContext.axisVertical1.minorDivisions-1;
    [self updateGraphAxisUI:self->axis2Control.gridMinorTextField];
    [self->graphView setNeedsDisplay:YES];
    result = YES;
  }//end if (stepper == self->axis2Control.gridMinorStepper)
  chalkGmpFlagsRestore(oldFlags);
  return result;
}
//end stepperShouldDecrement:

#pragma mark CHGraphViewDelegate

-(void) graphView:(CHGraphView*)graphView didUpdateCursorValue:(CHGraphCurve*)graphCurve
{
  NSString* xString = self->graphView.xString;
  NSString* yString = self->graphView.yString;
  [self->cursorValueXTextField setStringValue:
    [NSString stringWithFormat:@"x=%@", [NSString isNilOrEmpty:xString] ? @"-" : xString]];
  [self->cursorValueYTextField setStringValue:
    [NSString stringWithFormat:@"y=%@", [NSString isNilOrEmpty:yString] ? @"-" : yString]];
}
//end graphView:didUpdateCursorValue:

-(void) graphView:(CHGraphView*)graphView didChangeAxis:(chgraph_axis_orientation_flags_t)axisFlags didZoom:(BOOL)didZoom
{
  if ((axisFlags & CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) != 0)
  {
    [self updateGraphAxisUI:self->axis1Control.minTextField];
    [self updateGraphAxisUI:self->axis1Control.maxTextField];
  }//end ((axisFlags & CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) != 0)
  if ((axisFlags & CHGRAPH_AXIS_ORIENTATION_VERTICAL) != 0)
  {
    [self updateGraphAxisUI:self->axis2Control.minTextField];
    [self updateGraphAxisUI:self->axis2Control.maxTextField];
  }//end if ((axisFlags & CHGRAPH_AXIS_ORIENTATION_VERTICAL) != 0)
  if (didZoom)
    [self updateAutoMajorSteps];
}
//end graphView:didChangeAxis:didZoom:

-(void) graphView:(CHGraphView*)graphView didChangePreparingCurveWithCache:(CHGraphCurveCachedData*)cache
{
  CHGraphCurveItem* curveItem = [self curveItemForCurve:cache.curve];
  curveItem.isUpdating = cache.isPreparing;
}
//end graphView:didChangePreparingCurve:withCache:

-(NSUInteger) graphView:(CHGraphView*)graphView curveThicknessForCurve:(CHGraphCurve*)curve
{
  NSUInteger result = [self curveItemForCurve:curve].curveThickness;
  return result;
}
//end graphView:curveThicknessForCurve:

-(NSColor*) graphView:(CHGraphView*)graphView curveColorForCurve:(CHGraphCurve*)curve
{
  NSColor* result = [self curveItemForCurve:curve].curveColor;
  return result;
}
//end graphView:curveColorForCurve:

-(NSColor*) graphView:(CHGraphView*)graphView curveInteriorColorForCurve:(CHGraphCurve*)curve
{
  NSColor* result = [self curveItemForCurve:curve].curveInteriorColor;
  return result;
}
//end graphView:curveInteriorColorForCurve:

-(BOOL) graphView:(CHGraphView*)graphView curveUncertaintyVisibleForCurve:(CHGraphCurve*)curve
{
  BOOL result = [self curveItemForCurve:curve].curveUncertaintyVisible;
  return result;
}
//end graphView:curveUncertaintyVisibleForCurve:

-(NSColor*) graphView:(CHGraphView*)graphView curveUncertaintyColorForCurve:(CHGraphCurve*)curve
{
  NSColor* result = [self curveItemForCurve:curve].curveUncertaintyColor;
  return result;
}
//end graphView:curveUncertaintyColorForCurve:

-(BOOL) graphView:(CHGraphView*)graphView curveUncertaintyNaNVisibleForCurve:(CHGraphCurve*)curve
{
  BOOL result = [self curveItemForCurve:curve].curveUncertaintyNaNVisible;
  return result;
}
//end graphView:curveUncertaintyVisibleForCurve:

-(NSColor*) graphView:(CHGraphView*)graphView curveUncertaintyNaNColorForCurve:(CHGraphCurve*)curve
{
  NSColor* result = [self curveItemForCurve:curve].curveUncertaintyNaNColor;
  return result;
}
//end graphView:curveUncertaintyNaNColorForCurve:

-(NSColor*) graphView:(CHGraphView*)graphView predicateColorFalseForCurve:(CHGraphCurve*)curve
{
  NSColor* result = [self curveItemForCurve:curve].predicateColorFalse;
  return result;
}
//end graphView:predicateColorFalseForCurve:

-(NSColor*) graphView:(CHGraphView*)graphView predicateColorTrueForCurve:(CHGraphCurve*)curve
{
  NSColor* result = [self curveItemForCurve:curve].predicateColorTrue;
  return result;
}
//end graphView:predicateColorTrueForCurve:

-(NSFont*) graphViewFont:(CHGraphView*)graphView
{
  NSFont* result = self->graphFont;
  return result;
}
//end graphViewFont:

-(NSColor*) graphViewBackgroundColor:(CHGraphView*)graphView
{
  NSColor* result = self->backgroundColorWell.color;
  return result;
}
//end graphViewBackgroundColor:

-(NSColor*) graphView:(CHGraphView*)graphView axisColorForOrientation:(chgraph_axis_orientation_flags_t)orientation
{
  NSColor* result =
    (orientation == CHGRAPH_AXIS_ORIENTATION_HORIZONTAL) ? self->axis1Control.axisColor :
    (orientation == CHGRAPH_AXIS_ORIENTATION_VERTICAL) ? self->axis2Control.axisColor :
    nil;
  return result;
}
//end graphView:axisColorForOrientation:

#pragma mark NSWindowDelegate

-(void) windowWillStartLiveResize:(NSNotification*)notification
{
  self->graphView.isWindowResizing = YES;
}
//end windowWillStartLiveResize:

-(void) windowDidEndLiveResize:(NSNotification *)notification
{
  self->graphView.isWindowResizing = NO;
  [self->graphView setNeedsDisplay:YES];
}
//end windowDidEndLiveResize:

-(void) windowDidResize:(NSNotification*)notification
{
  [self->graphActionSegmentedControl centerRelativelyTo:self->graphView horizontally:YES vertically:NO];
  [self->graphSnapshotPopUpButton centerRelativelyTo:self->graphView horizontally:YES vertically:NO];
}
//end windowDidResize:

#pragma mark NSTableViewDelegate

-(void) tableViewSelectionDidChange:(NSNotification*)notification
{
  if (!notification || (notification.object == self->functionsTableView))
  {
    if (self->functionsTableView.selectedRowIndexes.count)
      [self->userVariableItemsTableView deselectAll:self];
    [self updateInputControls];
  }//end if (notification.object == self->functionsTableView)
  else if (notification.object == self->userVariableItemsTableView)
  {
    if (self->userVariableItemsTableView.selectedRowIndexes.count)
      [self->functionsTableView deselectAll:self];
    [self updateInputControls];
  }//end if (notification.object == self->userVariableItemsTableView)
  if (self->userVariableItemsTableView.selectedRowIndexes.count)
    ((NSTextFieldCell*)self->inputTextField.cell).placeholderString = NSLocalizedString(@"value", @"");
  else
    ((NSTextFieldCell*)self->inputTextField.cell).placeholderString = NSLocalizedString(@"f(x) curve or f(x,y) predicate", @"");
}
//end tableViewSelectionDidChange:

-(id) tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row
{
  id result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:nil];
  NSTableCellView* tableCellView = [result dynamicCastToClass:[NSTableCellView class]];
  if (tableView == self->functionsTableView)
  {
    if ([tableColumn.identifier isEqualToString:@"enabled"])
    {
      CHGraphEnabledTableCellView* enabledCellView = [result dynamicCastToClass:[CHGraphEnabledTableCellView class]];
      [enabledCellView.checkBox bind:NSValueBinding toObject:tableCellView withKeyPath:@"objectValue.enabled" options:nil];
      [enabledCellView.checkBox bind:NSHiddenBinding toObject:tableCellView withKeyPath:@"objectValue.isUpdating" options:nil];
      [enabledCellView.progressIndicator bind:@"animated" toObject:tableCellView withKeyPath:@"objectValue.isUpdating" options:nil];
      [enabledCellView.progressIndicator bind:NSHiddenBinding toObject:tableCellView withKeyPath:@"objectValue.isUpdating" options:@{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];
    }//end if ([tableColumn.identifier isEqualToString:@"enabled"])
    else if ([tableColumn.identifier isEqualToString:@"color"])
    {
      CHColorWell* colorWell0 = (CHColorWell*)[tableCellView findSubviewOfClass:[CHColorWell class] andTag:0];
      CHColorWell* colorWell1 = (CHColorWell*)[tableCellView findSubviewOfClass:[CHColorWell class] andTag:1];
      CHColorWell* colorWell2 = (CHColorWell*)[tableCellView findSubviewOfClass:[CHColorWell class] andTag:2];
      colorWell0.allowAlpha = YES;
      colorWell1.allowAlpha = YES;
      colorWell2.allowAlpha = YES;
      CHColorWellButton* colorWellButton0 = (CHColorWellButton*)[tableCellView findSubviewOfClass:[CHColorWellButton class] andTag:0];
      CHColorWellButton* colorWellButton1 = (CHColorWellButton*)[tableCellView findSubviewOfClass:[CHColorWellButton class] andTag:1];
      CHColorWellButton* colorWellButton2 = (CHColorWellButton*)[tableCellView findSubviewOfClass:[CHColorWellButton class] andTag:2];
      colorWellButton0.delegate = self;
      colorWellButton1.delegate = self;
      colorWellButton2.delegate = self;
      [colorWell0 bind:NSValueBinding toObject:tableCellView withKeyPath:[NSString stringWithFormat:@"objectValue.%@", CHGraphCurveItemCurveColorKey] options:nil];
      [colorWell0 bind:NSEnabledBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:
        @{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];
      [colorWell0 bind:NSHiddenBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:nil];
      [colorWellButton0 bind:NSEnabledBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:
        @{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];
      [colorWellButton0 bind:NSHiddenBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:nil];
      [colorWell1 bind:NSValueBinding toObject:tableCellView withKeyPath:[NSString stringWithFormat:@"objectValue.%@", CHGraphCurveItemPredicateColorFalseKey] options:nil];
      [colorWell1 bind:NSEnabledBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:nil];
      [colorWell1 bind:NSHiddenBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:@{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];
      [colorWellButton1 bind:NSEnabledBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:nil];
      [colorWellButton1 bind:NSHiddenBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:@{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];
      [colorWell2 bind:NSValueBinding toObject:tableCellView withKeyPath:[NSString stringWithFormat:@"objectValue.%@", CHGraphCurveItemPredicateColorTrueKey] options:nil];
      [colorWell2 bind:NSEnabledBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:nil];
      [colorWell2 bind:NSHiddenBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:@{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];
      [colorWellButton2 bind:NSEnabledBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:nil];
      [colorWellButton2 bind:NSHiddenBinding toObject:tableCellView withKeyPath:@"objectValue.isPredicate" options:@{NSValueTransformerNameBindingOption:NSNegateBooleanTransformerName}];
    }//end if ([tableColumn.identifier isEqualToString:@"color"])
    else if ([tableColumn.identifier isEqualToString:@"name"])
    {
      CHGraphCurveNameTextField* curveNameTextField = [tableCellView.textField dynamicCastToClass:[CHGraphCurveNameTextField class]];
      [curveNameTextField bind:@"curveItem" toObject:tableCellView withKeyPath:@"objectValue" options:nil];
      [tableCellView.textField bind:NSValueBinding toObject:tableCellView withKeyPath:@"objectValue.name" options:nil];
    }//end if ([tableColumn.identifier isEqualToString:@"name"])
  }//end if (tableView == self->functionsTableView)
  else if (tableView == self->userVariableItemsTableView)
  {
    if ([tableColumn.identifier isEqualToString:@"name"])
    {
      [tableCellView.textField bind:NSValueBinding toObject:tableCellView withKeyPath:@"objectValue.name" options:nil];
    }//end if ([tableColumn.identifier isEqualToString:@"name"])
    else if ([tableColumn.identifier isEqualToString:@"evaluatedValueAttributedString"])
    {
      [tableCellView.textField bind:NSValueBinding toObject:tableCellView withKeyPath:@"objectValue.evaluatedValueAttributedString" options:nil];
      CHUserVariableItemTextField* userVariableItemTextField = [tableCellView.textField dynamicCastToClass:[CHUserVariableItemTextField class]];
      [userVariableItemTextField bind:@"userVariableItem" toObject:tableCellView withKeyPath:@"objectValue" options:nil];
    }//end if ([tableColumn.identifier isEqualToString:@"evaluatedValueAttributedString"])
  }//end if (tableView == self->userVariableItemsTableView)
  return result;
}
//end tableView:viewForTableColumn:row:

-(IBAction) openCurveParametersView:(id)sender
{
  NSButton* button = [sender dynamicCastToClass:[NSButton class]];
  if (!self->curveParametersPopOver)
  {
    if (!self->graphCurveParametersViewController)
      self->graphCurveParametersViewController = [[CHGraphCurveParametersViewController alloc] initWithNibName:@"CHGraphCurveParametersViewController" bundle:[NSBundle mainBundle]];
    self->graphCurveParametersViewController.target = self;
    self->graphCurveParametersViewController.action = @selector(changeInputParameter:);
    self->curveParametersPopOver = !self->graphCurveParametersViewController ? nil : [[NSPopover alloc] init];
    self->curveParametersPopOver.delegate = self;
    self->curveParametersPopOver.contentViewController = self->graphCurveParametersViewController;
    self->curveParametersPopOver.behavior = NSPopoverBehaviorTransient;
    self->curveParametersPopOver.animates = YES;
  }//end if (!self->curveParametersPopOver)
  if (self->curveParametersPopOver)
  {
    self->graphCurveParametersViewController.graphCurveItem = self.currentCurveItem;
    [self->curveParametersPopOver showRelativeToRect:button.bounds ofView:button preferredEdge:NSMaxYEdge];
  }//end if (self->curveParametersPopOver)
}
//end openCurveParametersView:

-(IBAction) changeFont:(id)sender
{
  NSFontManager* fontManager = [NSFontManager sharedFontManager];
  if (sender == self->graphFontButton)
  {
    fontManager.target = self;
    fontManager.action = @selector(changeFont:);
    NSFontPanel* fontPanel = [fontManager fontPanel:YES];
    [fontPanel orderFront:self];
  }//end if (sender == self->graphFontButton)
  else if (sender == [NSFontManager sharedFontManager])
  {
    self.graphFont = fontManager.selectedFont;
  }//end if (sender == [NSFontManager sharedFontManager])
}
//end changeFont:

#pragma mark CHColorWellButtonDelegate
-(IBAction) changeColor:(id)sender
{
  [self updateGraphData:NO];
}
//end changeColor:

#pragma CHGraphCurveDelegate
-(void) graphCurveDidInvalidate:(NSNotification*)notification
{
  [self updateGraphData:YES];
}
//end graphCurveDidInvalidate:

#pragma CHGraphCurveItemDelegate
-(void) graphCurveItemDidInvalidate:(NSNotification*)notification
{
  [self updateGraphData:NO];
}
//end CHGraphCurveItemDelegate:

#pragma mark NSPopOverDelegate
-(void) popoverWillClose:(NSNotification*)notification
{
  if (notification.object == self->curveParametersPopOver)
    self->graphCurveParametersViewController.graphCurveItem = nil;
}
//end popoverWillClose:

-(void) printOperationDidRun:(NSPrintOperation*)printOperation success:(BOOL)success contextInfo:(void*)contextInfo
{
}
//end printOperationDidRun:success:contextInfo:

-(IBAction) printDocument:(id)sender
{
  //[self->outputWebView print:sender];
  NSPrintInfo* printInfo = [NSPrintInfo sharedPrintInfo];
  printInfo.horizontalPagination = NSFitPagination;
  printInfo.verticalPagination = NSFitPagination;
  printInfo.orientation = NSLandscapeOrientation;
  NSPrintOperation* printOperation = [NSPrintOperation printOperationWithView:self->graphView printInfo:printInfo];
  //[printOperation runOperation];
  [printOperation runOperationModalForWindow:self.windowForSheet
                                  delegate:self 
                            didRunSelector:@selector(printOperationDidRun:success:contextInfo:)
                               contextInfo:nil];
}
//end printDocument:

@end
