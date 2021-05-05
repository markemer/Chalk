//
//  NSObjectExtended.m
//  Chalk-Remote
//
//  Created by Pierre Chatelier on 16/03/07.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSObjectExtended.h"

@implementation NSObject (Extended)

+(Class) dynamicCastToClass:(Class)aClass
{
  Class result = ![self isSubclassOfClass:aClass] ? nil : aClass;
  return result;
}
//end dynamicCastToClass:

-(id) dynamicCastToClass:(Class)aClass
{
  id result = ![self isKindOfClass:aClass] ? nil : self;
  return result;
}
//end dynamicCastToClass:

-(id) dynamicCastToProtocol:(Protocol*)aProtocol
{
  id result = ![self conformsToProtocol:aProtocol] ? nil : self;
  return result;
}
//end dynamicCastToProtocol:

+(id) performSelector:(SEL)selector withArguments:(NSArray*)arguments
{
  id result = nil;
  NSMethodSignature* methodSignature = !selector ? nil : [self methodSignatureForSelector:selector];
  NSInvocation* invocation = !methodSignature ? nil : [NSInvocation invocationWithMethodSignature:methodSignature];
  if (!methodSignature){
  }
  else if ((2+arguments.count) == methodSignature.numberOfArguments)//do not forget self and _cmd !
  {
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [invocation setArgument:&obj atIndex:2+idx];
    }];
    [invocation invoke];
    [invocation getReturnValue:&result];
  }//end if (arguments.count == methodSignature.numberOfArguments)
  return result;
}
//end performSelector:withArguments:

-(id) performSelector:(SEL)selector withArguments:(NSArray*)arguments
{
  id result = nil;
  NSMethodSignature* methodSignature = !selector ? nil : [self methodSignatureForSelector:selector];
  NSInvocation* invocation = !methodSignature ? nil : [NSInvocation invocationWithMethodSignature:methodSignature];
  if (!methodSignature){
  }
  else if ((2+arguments.count) == methodSignature.numberOfArguments)//do not forget self and _cmd !
  {
    [invocation setTarget:self];
    [invocation setSelector:selector];
    [arguments enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [invocation setArgument:&obj atIndex:2+idx];
    }];
    [invocation invoke];
    if ([methodSignature methodReturnLength] == sizeof(result))
      [invocation getReturnValue:&result];
  }//end if (arguments.count == methodSignature.numberOfArguments)
  return result;
}
//end performSelector:withArguments:

-(void) propagateValue:(id)value forBinding:(NSString*)binding;
{
  NSParameterAssert(binding != nil);

  //WARNING: bindingInfo contains NSNull, so it must be accounted for
  NSDictionary* bindingInfo = [self infoForBinding:binding];
  if(!bindingInfo)
      return; //there is no binding

  //apply the value transformer, if one has been set
  NSDictionary* bindingOptions = [bindingInfo objectForKey:NSOptionsKey];
  if(bindingOptions){
      NSValueTransformer* transformer = [bindingOptions valueForKey:NSValueTransformerBindingOption];
      if(!transformer || (id)transformer == [NSNull null]){
          NSString* transformerName = [bindingOptions valueForKey:NSValueTransformerNameBindingOption];
          if(transformerName && (id)transformerName != [NSNull null]){
              transformer = [NSValueTransformer valueTransformerForName:transformerName];
          }
      }

      if(transformer && (id)transformer != [NSNull null]){
          if([[transformer class] allowsReverseTransformation]){
              value = [transformer reverseTransformedValue:value];
          } else {
              NSLog(@"WARNING: binding \"%@\" has value transformer, but it doesn't allow reverse transformations in %s", binding, __PRETTY_FUNCTION__);
          }
      }
  }

  id boundObject = [bindingInfo objectForKey:NSObservedObjectKey];
  if(!boundObject || boundObject == [NSNull null]){
      NSLog(@"ERROR: NSObservedObjectKey was nil for binding \"%@\" in %s", binding, __PRETTY_FUNCTION__);
      return;
  }

  NSString* boundKeyPath = [bindingInfo objectForKey:NSObservedKeyPathKey];
  if(!boundKeyPath || (id)boundKeyPath == [NSNull null]){
      NSLog(@"ERROR: NSObservedKeyPathKey was nil for binding \"%@\" in %s", binding, __PRETTY_FUNCTION__);
      return;
  }

  [boundObject setValue:value forKeyPath:boundKeyPath];
}
//end propagateValue:forBinding:

+(id) nullAdapter:(id)object
{
  id result = !object ? [NSNull null] : object;
  return result;
}
//end nullAdapter:

@end

