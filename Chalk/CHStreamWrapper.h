//
//  CHStreamWrapper.h
//  Chalk
//
//  Created by Pierre Chatelier on 17/03/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHStreamWrapper : NSObject {
  NSMutableAttributedString* attributedStringStream;
  NSMutableString* stringStream;
  NSMutableData* dataStream;
  FILE* fileStream;
}

@property(nonatomic, retain) NSMutableAttributedString* attributedStringStream;
@property(nonatomic, retain) NSMutableString* stringStream;
@property(nonatomic, retain) NSMutableData* dataStream;
@property(nonatomic)         FILE* fileStream;
@property(nonatomic,copy)    NSDictionary* currentAttributes;

-(void) reset;

-(void) writeAttributedString:(NSAttributedString*)attributedString;
-(void) writeAttributedString:(NSAttributedString*)attributedString bold:(BOOL)bold italic:(BOOL)italic;
-(void) writeString:(NSString*)attributedString bold:(BOOL)bold italic:(BOOL)italic;
-(void) writeString:(NSString*)string;
-(void) writeString:(NSString*)string groupSize:(NSInteger)groupSize groupOffset:(NSUInteger)groupOffset space:(NSString*)space;
-(BOOL) writeCharacter:(char)character count:(NSUInteger)count;
-(BOOL) writeCharacter:(char)character count:(NSUInteger)count groupSize:(NSInteger)groupSize groupOffset:(NSUInteger)groupOffset space:(NSString*)space;

@end
