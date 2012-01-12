//
//  DGLogger.m
//  DGLogger
//
//  Created by wang  chao on 11-12-18.
//  Copyright 2011年 bupt. All rights reserved.
//

#import "DGLogger.h"

static _DGLogger* _instance;

@implementation _DGLogger

@synthesize logLevel = _logLevel;
@synthesize ruleTags = _ruleTags;
@synthesize filterRule = _filterRule;
@synthesize showLevel = _showLevel;

- (id)init
{
    self = [super init];
    if (self) {
        _logLevel = DL_ERROR | DL_WARNING | DL_INFO | DL_VERBOSE;
        _filterRule = DR_DISALLOW;
    }
    
    return self;
}

+ (id)instance{
    if (!_instance) {
        _instance = [[_DGLogger alloc] init];
    }
    return _instance;
}

- (NSString*)nameOfLevel:(DGLogLevel)level{
    if (level == DL_ERROR) {
        return @"ERROR";
    }else if(level == DL_WARNING){
        return @"WARNING";
    }else if(level == DL_INFO){
        return @"INFO";
    }else if(level == DL_VERBOSE){
        return @"VERBOSE";
    }
    return @"UNKNOWN";
}

- (BOOL)isTagInTagList:(NSString*)tag{
    if (_ruleTags == nil) {
        return NO;
    }
    
    for (NSString* ruleTag in _ruleTags) {
        if ([ruleTag isEqualToString:tag]) {
            return YES;
        }
    }
    return NO;
}

- (void)log:(DGLogLevel)level tag:(NSString*)tag message:(NSString*)message{
    NSString* printTag = @"";
    if (tag == nil || [tag isEqualToString:@""]) {
        tag = @"";
    }else{
        printTag = [NSString stringWithFormat:@":%@",tag];
    }
    
    BOOL print = NO;
    
    if (level&_logLevel) {
        if (_filterRule == DR_ALLOW && [self isTagInTagList:tag]) {
            print = YES;
        }
        
        if (_filterRule == DR_DISALLOW && ![self isTagInTagList:tag]) {
            print = YES;
        }
    }
        
    if (print) {
        NSLog(@"- [%@%@]:\n %@",[self nameOfLevel:level],printTag,message);
    }
}

- (void)dealloc{
    [_ruleTags release];
    [super dealloc];
}

@end

void DGLoggerLevel(int level){
    _DGLogger* logger = [_DGLogger instance];
    logger.logLevel = level;
}

void DGLoggerFilter(DGFilterRule rule,NSArray* list){
    _DGLogger* logger = [_DGLogger instance];
    logger.filterRule = rule;
    logger.ruleTags = list;
}

void _DGLogMessage(NSString* message){
    _DGLogMessageLevelTag(message,DL_VERBOSE,@"");
}

void _DGLogMessageTag(NSString* message,NSString* tag){
    _DGLogMessageLevelTag(message,DL_VERBOSE,tag);
}

void _DGLogMessageLevel(NSString* message,DGLogLevel level){
    _DGLogMessageLevelTag(message,level,@"");
}

void _DGLogMessageLevelTag(NSString* message,DGLogLevel level,NSString* tag){
    _DGLogger* logger = [_DGLogger instance];
    [logger log:level tag:tag message:message];
}

