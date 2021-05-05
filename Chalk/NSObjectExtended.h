//
//  NSObjectExtended.h
//  Chalk-Remote
//
//  Created by Pierre Chatelier on 16/03/07.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

@interface NSObject (Extended)

+(Class) dynamicCastToClass:(Class)aClass;
-(id)    dynamicCastToClass:(Class)aClass;
-(id)    dynamicCastToProtocol:(Protocol*)aProtocol;
+(id)    performSelector:(SEL)selector withArguments:(NSArray*)arguments;
-(id)    performSelector:(SEL)selector withArguments:(NSArray*)arguments;
-(void)  propagateValue:(id)value forBinding:(NSString*)binding;

+(id) nullAdapter:(id)object;

@end
