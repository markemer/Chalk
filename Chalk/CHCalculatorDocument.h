//
//  CHCalculatorDocument.h
//  Chalk
//
//  Created by Pierre Chatelier on 12/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "CHChalkContext.h"
#import "CHDigitsInspectorControl.h"
#import "CHPersistentDocument.h"
#import "CHWebView.h"

@class CHChalkIdentifierManager;
@class CHChalkItemDependencyManager;
@class CHChalkOperatorManager;
@class CHChalkValueToStringTransformer;
@class CHComputationEntryEntity;
@class CHComputationConfiguration;
@class CHPresentationConfiguration;
@class CHInspectorView;
@class CHProgressIndicator;
@class CHSVGRenderer;
@class CHTableView;
@class CHWebView;

@interface CHCalculatorDocument : CHPersistentDocument
                                    <CHChalkContextHistoryDelegate, CHDigitsInspectorControlDelegate, CHWebViewDelegate,
                                    NSControlTextEditingDelegate,
                                    NSTableViewDataSource, NSTableViewDelegate,
                                    NSTextFieldDelegate, NSTextViewDelegate,
                                    NSToolbarDelegate,
                                    NSWindowDelegate>
{
  IBOutlet NSView*              windowContentView;
  IBOutlet CHInspectorView*     inspectorLeftView;
  IBOutlet NSView*              centerView;
  IBOutlet CHInspectorView*     inspectorRightView;
  IBOutlet CHInspectorView*     inspectorBottomView;
  IBOutlet NSView*              computationEntryPanel;
  IBOutlet NSTextField*         variablesLabel;
  IBOutlet CHTableView*         userVariableItemsTableView;
  IBOutlet NSButton*            userVariableItemsAddButton;
  IBOutlet NSButton*            userVariableItemsRemoveButton;
  IBOutlet NSTextField*         functionsLabel;
  IBOutlet CHTableView*         userFunctionItemsTableView;
  IBOutlet NSButton*            userFunctionItemsRemoveButton;
  IBOutlet NSView*              disablingView;
  IBOutlet NSProgressIndicator* progressIndicator;
  IBOutlet CHWebView*           outputWebView;
  IBOutlet NSTextField*         inputTextField;
  IBOutlet NSProgressIndicator* inputProgressIndicator;
  IBOutlet NSButton*            inputComputeButton;
  IBOutlet CHProgressIndicator* inputComputeButtonProgressIndicator;
  IBOutlet NSNumberFormatter*   softFloatDisplayBitsNumberFormatter;
  IBOutlet NSTextField*         computeOptionSoftFloatDisplayBitsLabel;
  IBOutlet NSSlider*            computeOptionSoftFloatDisplayBitsSlider;
  IBOutlet NSTextField*         computeOptionSoftFloatDisplayBitsTextField;
  IBOutlet NSStepper*           computeOptionSoftFloatDisplayBitsStepper;
  IBOutlet NSSegmentedControl*  computeOptionComputeModeSegmentedControl;
  IBOutlet NSTextField*         computeOptionOutputBaseLabel;
  IBOutlet NSTextField*         computeOptionOutputBaseTextField;
  IBOutlet NSStepper*           computeOptionOutputBaseStepper;
  IBOutlet NSTextField*         computeOptionIntegerGroupSizeLabel;
  IBOutlet NSTextField*         computeOptionIntegerGroupSizeTextField;
  IBOutlet NSStepper*           computeOptionIntegerGroupSizeStepper;
  IBOutlet NSPopUpButton*       inputPopUpButton;
  IBOutlet NSPopUpButton*       outputPopUpButton;
  IBOutlet NSColorWell*         inputColorColorWell;
  IBOutlet NSColorWell*         outputColorColorWell;
  IBOutlet NSPopUpButton*       themesPopUpButton;
  IBOutlet NSToolbarItem*       themesToolbarItem;
  IBOutlet NSToolbarItem*       inspectorLeftToolbarItem;
  IBOutlet NSToolbarItem*       inspectorRightToolbarItem;
  IBOutlet NSToolbarItem*       inspectorBottomToolbarItem;
  NSMutableArray*                  availableThemes;
  NSString*                        defaultLightTheme;
  NSString*                        defaultDarkTheme;
  NSString*                        currentTheme;
  CHDigitsInspectorControl*        digitsInspectorControl;
  CHChalkIdentifierManager*        chalkIdentifierManager;
  CHChalkOperatorManager*          chalkOperatorManager;
  CHChalkContext*                  chalkContext;
  NSString*                        ans0;
  BOOL                             inhibateInputTextChange;
  NSArrayController*               userVariableItemsController;
  NSArrayController*               userFunctionItemsController;
  CHChalkItemDependencyManager*    dependencyManager;
  CHChalkValueToStringTransformer* chalkValueToStringTransformer;
  CHComputationEntryEntity*        currentComputationEntry;
  CHComputationConfiguration*      defaultComputationConfiguration;
  CHPresentationConfiguration*     defaultPresentationConfiguration;
  volatile BOOL                    isAnimating;
  id                               eventMonitor;
  CHChalkContext*                  computeChalkContext;
  BOOL                             nibLoaded;
  CHComputationEntryEntity*        scheduledComputationEntry;
  CHSVGRenderer*                   svgRenderer;
  NSUInteger                       isUpdatingPreferences;
  BOOL                             inputTextFieldIsDeleting;
}

@property(nonnull,nonatomic,readonly,assign) CHInspectorView* inspectorRightView;
@property(nonnull,nonatomic,readonly,assign) CHInspectorView* inspectorLeftView;
@property(nonnull,nonatomic,readonly,assign) CHInspectorView* inspectorBottomView;

@property(readonly) chalk_compute_mode_t currentComputeMode;
@property(nonatomic,readonly) BOOL isComputing;
@property(nullable,nonatomic,copy) CHComputationConfiguration* defaultComputationConfiguration;
@property(nullable,nonatomic,copy) CHPresentationConfiguration* defaultPresentationConfiguration;
@property(nullable,nonatomic,readonly,copy) CHComputationConfiguration* currentComputationConfiguration;
@property(nullable,nonatomic,readonly,copy) CHPresentationConfiguration* currentPresentationConfiguration;

@property(nonatomic,nullable,copy) NSString* currentTheme;

-(IBAction) toolbarAction:(id _Nullable)sender;
-(IBAction) addUserVariableItem:(id _Nullable)sender;
-(IBAction) removeUserVariableItem:(id _Nullable)sender;
-(IBAction) addUserFunctionItem:(id _Nullable)sender;
-(IBAction) removeUserFunctionItem:(id _Nullable)sender;
-(IBAction) startComputing:(id _Nullable)sender;
-(IBAction) stopComputing:(id _Nullable)sender;
-(IBAction) modifyComputationEntry:(id _Nullable)sender;
-(IBAction) removeCurrentEntry:(id _Nullable)sender;
-(IBAction) removeAllEntries:(id _Nullable)sender;
-(IBAction) doubleAction:(id _Nullable)sender;
-(IBAction) saveGUIState:(id _Nullable)sender saveDocument:(BOOL)saveDocument;
-(IBAction) changeColor:(id _Nullable)sender;
-(IBAction) feedPasteboard:(id _Nullable)sender;
-(IBAction) fontBigger:(id)sender;
-(IBAction) fontSmaller:(id)sender;

-(void) webviewDidLoad:(CHWebView* _Nonnull)webview;
-(void) jsDidLoad:(CHWebView* _Nonnull)webview;

-(BOOL) addConstantUserVariableItems:(NSArray* _Nullable)items;
-(void) removeUserVariableItems:(NSArray* _Nullable)items;
-(void) addUserVariableItems:(NSArray* _Nullable)items;
-(void) removeUserFunctionItems:(NSArray* _Nullable)items;
-(void) addUserFunctionItems:(NSArray* _Nullable)items;

@end
