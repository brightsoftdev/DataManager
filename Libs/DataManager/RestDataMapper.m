//
//  RestDataMapper.m
//  DemoRoom
//
//  Created by wang  chao on 12-1-5.
//  Copyright 2012年 bupt. All rights reserved.
//

#import "RestDataMapper.h"

@implementation RestDataMapper

@synthesize urlTemplate = _urlTemplate;

#pragma mark - construct methods

- (id)initWithKey:(NSString *)key urlTemplate:(NSString*)urlTemplate{
    self = [super initWithKey:key];
    if (self) {
        self.urlTemplate = urlTemplate;
    }
    return self;
}

#pragma mark -

- (HttpRequest*)generateRequest:(NSDictionary*)params method:(NSString*)method{
    if (!method) {
        method = @"GET";
    }
    NSString* urlStr = _urlTemplate;
    NSMutableDictionary* otherParmas = [NSMutableDictionary dictionaryWithDictionary:params];
    for (NSString* key in params) {
        NSString* temKey = [NSString stringWithFormat:@"{%@}",key];
        if ([_urlTemplate rangeOfString:temKey options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [otherParmas removeObjectForKey:key];
            NSString* replaceStr = [[params objectForKey:key] URLEncodeString];
            urlStr = [urlStr stringByReplacingOccurrencesOfString:temKey withString:replaceStr];
        }
    }
    HttpRequest* request = [[[HttpRequest alloc] initWithURL:[NSURL URLWithString:urlStr]] autorelease];
    request.HTTPMethod = method;
    request.params = otherParmas;
    return request;
}

#pragma mark - overried
/*
- (NSString*)keyPathForParams:(NSDictionary*)params{
    NSDictionary* normalParams = [DataMapper normalParams:params];
    HttpRequest* request = [self generateRequest:normalParams method:@"GET"];
    return request.url.absoluteString;
}
*/

- (void)_getValue:(NSDictionary *)params handler:(DataHandler)handler{
    HttpRequest* request = [self generateRequest:params method:nil];
    HttpSender* sender = [[HServer instance] sendRequest:request delegate:nil];
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = _key;
    info.params = params;
    
    sender.successHandler = ^(HttpSender* sender,id data){
        info.data = data;
        info.updateTime = [[NSDate date] timeIntervalSince1970];
        if (handler) {
            handler(info,nil);
        }

    };
     

    sender.failedHandler = ^(HttpSender* sender,id data){
        NSError* error = [NSError errorWithDomain:@"RestMapper" code:sender.response.statusCode userInfo:nil];
        if (handler) {
            handler(info,error);
        }

    };

}

- (void)_updateValue:(NSDictionary *)params value:(id)value handler:(DataHandler)handler{
    NSDictionary* normalParmas = [DataMapper normalParams:params];
    NSDictionary* hiddenParams = [DataMapper hiddenParams:params];
    NSString* method = [hiddenParams objectForKey:@"method"];
    if (!method) {
        method = @"POST";
    }
    HttpRequest* request = [self generateRequest:normalParmas method:method];
    
    for (NSString* key in hiddenParams) {
        if ([key isEqualToString:@"method"]) {
            continue;
        }
        [request setValue:[hiddenParams objectForKey:key] forHTTPHeaderField:key];
    }
    
    request.params = value;
    if ([value isKindOfClass:[NSDictionary class]]) {
        request.params = value;
    }else if([value isKindOfClass:[NSString class]]){
        request.HTTPBody = [value dataUsingEncoding:NSUTF8StringEncoding];
    }else{
        request.HTTPBody = nil;
    }
    HttpSender* sender = [[HServer instance] sendRequest:request delegate:nil];
    DataInfo* info = [[[DataInfo alloc] init] autorelease];
    info.key = _key;
    info.params = params;
    
    sender.successHandler = ^(HttpSender* sender,id data){
        info.data = nil;
        info.updateTime = [[NSDate date] timeIntervalSince1970];
        if (handler) {
            handler(info,nil);
        }
        
    };
    
    
    sender.failedHandler = ^(HttpSender* sender,id data){
        NSError* error = [NSError errorWithDomain:@"RestMapper" code:sender.response.statusCode userInfo:nil];
        if (handler) {
            handler(info,error);
        }
        
    };
}

#pragma mark - manage memory

- (void)dealloc{
    [_urlTemplate release];
    [super dealloc];
}

@end
