//
//  CHConstantDescriptionPresenter.h
//  Chalk
//
//  Created by Pierre Chatelier on 28/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHConstantDescription;
@class CHConstantSymbolManager;
@class CHUnit;

@interface CHConstantDescriptionPresenter : NSObject<NSCopying,NSPasteboardWriting> {
  CHConstantDescription* constantDescription;
  CHConstantSymbolManager* constantSymbolManager;
  NSUInteger selectedUnitIndex;
}

@property(nonatomic, readonly, retain) CHConstantDescription* constantDescription;
@property(nonatomic, readonly, copy) NSString* name;
@property(nonatomic, readonly, copy) NSString* value;
@property(nonatomic, readonly, copy) NSString* uncertainty;
@property(nonatomic, readonly, copy) NSArray<NSAttributedString*>* commonUnitsRichDescriptions;
@property(nonatomic, readonly, retain) NSImage* texSymbolImage;

@property(nonatomic, copy) NSAttributedString* richDescription;
@property(nonatomic, copy) NSAttributedString* selectedUnitRichDescription;

-(instancetype) initWithConstantDescription:(CHConstantDescription*)aConstantDescription constantSymbolManager:(CHConstantSymbolManager*)aConstantSymbolManager;
-(id) copyWithZone:(nullable NSZone*)zone;

@end

NS_ASSUME_NONNULL_END
