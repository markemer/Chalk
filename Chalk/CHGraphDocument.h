//
//  CHGraphDocument.h
//  Chalk
//
//  Created by Pierre Chatelier on 08/05/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CHColorWellButton.h"
#import "CHGraphCurve.h"
#import "CHGraphCurveItem.h"
#import "CHGraphView.h"
#import "CHPersistentDocument.h"
#import "CHStepper.h"

@class CHChalkContext;
@class CHChalkValueToStringTransformer;
@class CHColorWell;
@class CHGmpPool;
@class CHGraphAxisControl;
@class CHGraphCurveParametersViewController;
@class CHInspectorView;
@class CHUserVariableItem;
@class CHChalkItemDependencyManager;
@class CHTableView;
@class CHViewColor;

@interface CHGraphDocument : CHPersistentDocument <CHColorWellButtonDelegate, CHGraphCurveItemDelegate, CHGraphCurveDelegate, CHGraphViewDelegate, CHStepperDelegate, NSPopoverDelegate, NSTableViewDelegate, NSToolbarDelegate, NSWindowDelegate> {
  IBOutlet NSView*              windowContentView;
  IBOutlet CHInspectorView*     inspectorLeftView;
  IBOutlet CHInspectorView*     inspectorRightView;
  IBOutlet NSView*              centerView;
  IBOutlet NSToolbarItem* inspectorLeftToolbarItem;
  IBOutlet NSToolbarItem* inspectorRightToolbarItem;
  IBOutlet CHViewColor* graphBackgroundColorView;
  IBOutlet CHGraphView* graphView;
  IBOutlet NSTextField* inputTextField;
  IBOutlet NSProgressIndicator* inputProgressIndicator;
  IBOutlet NSButton* curveParametersButton;
  IBOutlet NSSegmentedControl* graphActionSegmentedControl;
  IBOutlet NSPopUpButton* graphSnapshotPopUpButton;
  IBOutlet CHColorWell* backgroundColorWell;
  IBOutlet NSButton* graphFontButton;
  IBOutlet NSTextField* cursorValueXTextField;
  IBOutlet NSTextField* cursorValueYTextField;
  IBOutlet CHTableView* functionsTableView;
  IBOutlet NSButton* functionsAddButton;
  IBOutlet NSButton* functionsRemoveButton;
  IBOutlet CHTableView* userVariableItemsTableView;
  IBOutlet NSButton* userVariableItemsAddButton;
  IBOutlet NSButton* userVariableItemsRemoveButton;
  IBOutlet NSView* axis1ControlWrapper;
  IBOutlet NSView* axis2ControlWrapper;
  CHGraphAxisControl* axis1Control;
  CHGraphAxisControl* axis2Control;
  NSFont* graphFont;
  CHChalkContext* chalkContext;
  CHGmpPool* gmpPool;
  CHGraphCurve* detachedCurve;
  CHGraphCurveItem* detachedCurveItem;
  NSArrayController* curvesController;
  NSArrayController* userVariableItemsController;
  CHChalkItemDependencyManager* dependencyManager;
  CHChalkValueToStringTransformer* chalkValueToStringTransformer;
  CHGraphCurveParametersViewController* graphCurveParametersViewController;
  NSPopover* curveParametersPopOver;
  volatile BOOL isAnimating;
  BOOL nibLoaded;
}

@property(nonatomic,readonly,assign) CHInspectorView* inspectorRightView;
@property(nonatomic,readonly,assign) CHInspectorView* inspectorLeftView;

@property(readonly,assign) CHGraphCurve* currentCurve;
@property(readonly,assign) CHGraphCurveItem* currentCurveItem;
@property(readonly,assign) CHUserVariableItem* currentUserVariableItem;

@property(nonatomic,copy) NSFont* graphFont;

-(IBAction) toolbarAction:(id)sender;
-(IBAction) centerAxes:(id)sender;
-(IBAction) addFunction:(id)sender;
-(IBAction) removeFunction:(id)sender;
-(IBAction) addUserVariableItem:(id)sender;
-(IBAction) removeUserVariableItem:(id)sender;
-(IBAction) inputDidChange:(id)sender;
-(IBAction) changeInputParameter:(id)sender;
-(IBAction) makeSnapshot:(id)sender;
-(IBAction) changeGraphAction:(id)sender;

-(BOOL) stepperShouldIncrement:(CHStepper*)stepper;
-(BOOL) stepperShouldDecrement:(CHStepper*)stepper;

-(IBAction) changeColor:(id)sender;
-(IBAction) changeFont:(id)sender;
-(IBAction) openCurveParametersView:(id)sender;

@end
