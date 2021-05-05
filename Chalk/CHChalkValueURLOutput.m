//
//  CHChalkValueURLOutput.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueURLOutput.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"

@implementation CHChalkValueURLOutput

+(BOOL) supportsSecureCoding {return YES;}

-(void) write:(NSData*)data append:(BOOL)append context:(CHChalkContext*)context
{
  NSString* filePath = [self->url path];
  FILE* fp = fopen([filePath UTF8String], append ? "aw+b" : "w+b");
  int fd = fileno(fp);
  if (fd<0)
    [context.errorContext setError:
      [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainDataAccess reason:CHChalkErrorDataOpen range:self->token.range]
      replace:NO];
  else//if (fd>=0)
  {
    size_t remainingBytes = data.length;
    const char* reader = data.bytes;
    BOOL stop = !reader || !remainingBytes;
    while(!stop)
    {
      size_t written = write(fd, reader, remainingBytes);
      reader += written;
      remainingBytes -= written;
      stop |= !written || !remainingBytes;
    }//end while(!stop)
    if (remainingBytes > 0)
      [context.errorContext setError:
        [CHChalkError chalkErrorWithDomain:CHChalkErrorDomainDataAccess reason:CHChalkErrorDataWrite range:self->token.range]
      replace:NO];
    //close(fd);
    fclose(fp);
  }//end if (fd>=0)
}
//end write:append:context:

@end
