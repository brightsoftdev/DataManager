//
//  DGLogger.h
//  DGLogger
//
//  Created by wang  chao on 11-12-18.
//  Copyright 2011年 bupt. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DG_DEBUG

typedef enum{
    DL_ERROR = 0x1,
    DL_WARNING = 0x2,
    DL_INFO = 0x4,
    DL_VERBOSE = 0x8
}DGLogLevel;

typedef enum{
    DR_ALLOW = 1,
    DR_DISALLOW
}DGFilterRule;

@interface _DGLogger : NSObject{
    int _logLevel;
    int _showLevel;
    DGFilterRule _filterRule;
    NSArray* _ruleTags;
}

@property (nonatomic,assign) int logLevel;
@property (nonatomic,assign) int showLevel;
@property (nonatomic,assign) DGFilterRule filterRule;
@property (nonatomic,retain) NSArray* ruleTags;

+ (id)instance;

- (void)log:(DGLogLevel)level tag:(NSString*)tag message:(NSString*)message;
- (NSString*)nameOfLevel:(DGLogLevel)level;
- (BOOL)isTagInTagList:(NSString*)tag;

@end

void DGLoggerLevel(int level);
void DGLoggerFilter(DGFilterRule rule,NSArray* list);
void _DGLogMessage(NSString* message);
void _DGLogMessageTag(NSString* message,NSString* tag);
void _DGLogMessageLevel(NSString* message,DGLogLevel level);
void _DGLogMessageLevelTag(NSString* message,DGLogLevel level,NSString* tag);

#ifdef DG_DEBUG

#define DGLog(FMT,...)\
    do{\
        NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
        _DGLogMessage(message);\
    }while(0);

#define DGLogT(TAG,FMT,...)\
do{\
NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
_DGLogMessageTag(message,TAG);\
}while(0);

///////////////////////
#define DGLogError(FMT,...)\
do{\
NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
_DGLogMessageLevel(message,DL_ERROR);\
}while(0);

#define DGLogWarn(FMT,...)\
do{\
NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
_DGLogMessageLevel(message,DL_WARNING);\
}while(0);

#define DGLogInfo(FMT,...)\
do{\
NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
_DGLogMessageLevel(message,DL_INFO);\
}while(0);

#define DGLogVerb(FMT,...)\
do{\
NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
_DGLogMessageLevel(message,DL_VERBOSE);\
}while(0);

/////////////////

#define DGLogErrorT(TAG,FMT,...)\
do{\
NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
_DGLogMessageLevelTag(message,DL_ERROR,TAG);\
}while(0);

#define DGLogWarnT(TAG,FMT,...)\
do{\
NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
_DGLogMessageLevelTag(message,DL_WARNING,TAG);\
}while(0);

#define DGLogInfoT(TAG,FMT,...)\
do{\
NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
_DGLogMessageLevelTag(message,DL_INFO,TAG);\
}while(0);

#define DGLogVerbT(TAG,FMT,...)\
do{\
NSString* message = [NSString stringWithFormat:FMT, ##__VA_ARGS__];\
_DGLogMessageLevelTag(message,DL_VERBOSE,TAG);\
}while(0);

#else

#define DGLog(FMT,...)
#define DGLogT(TAG,FMT,...)
#define DGLogError(FMT,...)
#define DGLogWarn(FMT,...)
#define DGLogInfo(FMT,...)
#define DGLogVerb(FMT,...)
#define DGLogErrorT(TAG,FMT,...)
#define DGLogWarnT(TAG,FMT,...)
#define DGLogInfoT(TAG,FMT,...)
#define DGLogVerbT(TAG,FMT,...)

#endif






