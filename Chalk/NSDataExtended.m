//
//  NSDataExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 19/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSDataExtended.h"

#include <bzlib.h>

struct NSData_file
{
  NSData* data;
  NSUInteger location;
};

static int NSData_file_read(void* cookie, char* buffer, int count)
{
  int result = 0;
  struct NSData_file* context = (struct NSData_file*)cookie;
  if (context && (count>0))
  {
    size_t sizeToRead = ([context->data length]<context->location) ? 0 :
      MIN(count, [context->data length]-context->location);
    memcpy(buffer, [context->data bytes]+context->location, sizeToRead);
    context->location += sizeToRead;
    result = (int)sizeToRead;
  }//end if (context && (count>0))
  return result;
}
//end NSData_file_read()

static int NSData_file_write(void* cookie, const char* buffer, int count)
{
  int result = 0;
  struct NSData_file* context = (struct NSData_file*)cookie;
  if (context && (count>0))
  {
    @try{
      NSMutableData* mutableData = ![context->data isKindOfClass:[NSMutableData class]] ? nil :
        (NSMutableData*)context->data;
      NSUInteger minLength = context->location+count;
      if (mutableData && (minLength > mutableData.length))
        [mutableData setLength:minLength];
      unsigned char* mutableBytes = mutableData.mutableBytes;
      if (mutableBytes)
      {
        memcpy(mutableBytes+context->location, buffer, count);
        context->location += count;
        result = count;
      }//end if (mutableBytes)
    }//end @try
    @catch(NSException*){
    }//end @catch
  }//end if (context && (count>0))
  return result;
}
//end NSData_file_write()

static fpos_t NSData_file_seek(void* cookie, fpos_t offset, int whence)
{
  fpos_t result = 0;
  struct NSData_file* context = (struct NSData_file*)cookie;
  if (!context)
    result = -1;
  else if (whence == SEEK_SET)
  {
    if ((offset<0) || (offset > [context->data length]))
      result = -1;
    else//if ((offset>0) && (offset <= [context->data length]))
    {
      context->location = offset;
      result = offset;
    }//end if ((offset>0) && (offset <= [context->data length]))
  }//end if (whence == SEEK_SET)
  else if (whence == SEEK_CUR)
  {
    result = context->location+offset;
    if ((result<0) || (result>[context->data length]))
      result = -1;
    else//if ((result>=0) && (result<=[context->data length]))
      context->location = result;
  }//end if (whence == SEEK_CUR)
  else if (whence == SEEK_END)
  {
    result = [context->data length]+offset;
    if ((result<0) || (result>[context->data length]))
      result = -1;
    else//if ((result>=0) && (result<=[context->data length]))
      context->location = result;
  }//end if (whence == SEEK_END)
  return result;
}
//end NSData_file_seek()

static int NSData_file_close(void* cookie)
{
  int result = 0;
  struct NSData_file* context = (struct NSData_file*)cookie;
  if (!context)
    result = EOF;
  else//if (context)
  {
    [context->data release];
    free(context);
  }//end if (context)
  return result;
}
//end NSData_file_close()

@implementation NSData (Extended)

-(FILE*) openAsFile
{
  FILE* result = 0;
  struct NSData_file* cookie = calloc(1, sizeof(struct NSData_file));
  if (cookie)
  {
    BOOL isMutable = [self isKindOfClass:[NSMutableData class]];
    cookie->data = [self retain];
    result = funopen(cookie, &NSData_file_read, !isMutable ? 0 : &NSData_file_write,
                     &NSData_file_seek, &NSData_file_close);
    if (!result)
      free(cookie);
  }//end if (cookie)
  return result;
}
//end openAsFile

-(NSData*) bzip2Decompressed
{
  NSData* result = nil;
  NSMutableData* data = [[NSMutableData alloc] init];
  char* buffer = calloc(BZ_MAX_UNUSED, sizeof(char));
  FILE* inputAsFile = [self openAsFile];
  BOOL error = !buffer || !inputAsFile || !data;
  if (!error)
  {
    int bzError = 0;
    BZFILE* bzFile = BZ2_bzReadOpen(&bzError, inputAsFile, 0, 0, 0, 0);
    error |= !bzFile || (bzError != 0);
    @try{
      BOOL stop = error;
      while(!stop)
      {
        int read = BZ2_bzRead(&bzError, bzFile, buffer, BZ_MAX_UNUSED);
        if (read)
          [data appendBytes:buffer length:read];
        else
          error |= (bzError != BZ_STREAM_END);
        stop |= error || (bzError == BZ_STREAM_END);
      }//end while(!stop)
    }//end @try
    @catch(NSException* e){
      error = YES;
    }
    if (bzFile)
      BZ2_bzReadClose(&bzError, bzFile);
  }//end if (!error)
  if (!error)
    result = [[data copy] autorelease];
  [data release];
  if (inputAsFile)
    fclose(inputAsFile);
  if (buffer)
    free(buffer);
  return result;
}
//end bzip2Decompressed

@end
