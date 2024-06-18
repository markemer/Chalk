//
//  CHAppDelegate.h
//  Chalk
//
//  Created by Pierre Chatelier on 22/04/13.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

@class CHCalculatorDocument;
@class CHConstantsWindowController;
@class CHDragFilterWindowController;
@class CHPreferencesWindowController;
@class CHQuickReferenceWindowController;

@interface CHAppDelegate : NSObject <NSApplicationDelegate> {
  CHConstantsWindowController* constantsWindowController;
  CHDragFilterWindowController* dragFilterWindowController;
  CHPreferencesWindowController* preferencesWindowController;
  CHQuickReferenceWindowController* quickReferenceWindowController;
  SUUpdater* sparkleUpdater;
}

@property(readonly,assign,nonatomic) CHConstantsWindowController* constantsWindowController;
@property(readonly,assign,nonatomic) CHDragFilterWindowController* dragFilterWindowController;
@property(readonly,assign,nonatomic) CHPreferencesWindowController* preferencesWindowController;
@property(readonly,assign,nonatomic) CHQuickReferenceWindowController* quickReferenceWindowController;
@property(assign,nonatomic) IBOutlet SUUpdater* sparkleUpdater;

+(CHAppDelegate*) appDelegate;

-(IBAction) noAction:(id)sender;

-(IBAction) makeDonation:(id)sender;
-(IBAction) showPreferencesPane:(id)sender;
-(IBAction) openWebSite:(id)sender;
-(IBAction) checkUpdates:(id)sender;
-(IBAction) showHelp:(id)sender;
-(IBAction) showQuickHelp:(id)sender;

-(IBAction) toggleConstantsManager:(id)sender;
-(IBAction) toggleInspectorCompute:(id)sender;
-(IBAction) toggleInspectorVariables:(id)sender;
-(IBAction) toggleInspectorBits:(id)sender;
-(IBAction) toggleInspectorAxes:(id)sender;

-(IBAction) newDocument:(id)sender;
-(IBAction) saveDocument:(id)sender;
-(IBAction) newCalculatorDocument:(id)sender;
-(IBAction) newGraphDocument:(id)sender;
-(IBAction) newEquationDocument:(id)sender;
-(IBAction) renderEquationDocument:(id)sender;

-(IBAction) fontBigger:(id)sender;
-(IBAction) fontSmaller:(id)sender;

-(IBAction) calculatorRemoveCurrentItem:(id)sender;
-(IBAction) calculatorRemoveAllItems:(id)sender;

-(void) showPreferencesPaneWithItemIdentifier:(NSString*)itemIdentifier options:(id)options;

-(CHCalculatorDocument*) currentCalculatorDocument;

@end
