//
//  HServer.m
//  Signer
//
//  Created by mobroad on 11-6-14.
//  Copyright 2011 bupt. All rights reserved.
//

#import "HServer.h"
#import "DGLogger.h"

static HServer* hServer;

@interface HttpSender(Private)

- (void)runSend;

@end

@implementation HttpSender

@synthesize request = _request;
@synthesize delegate = _delegate;
@synthesize response = _response;
@synthesize driver = _driver;
@synthesize connection = _connection;

@synthesize successHandler = _successHandler;
@synthesize failedHandler = _failedHandler;

- (id)init{
    if ([super init]) {
        _driver = EVENT;
    }
    return self;
}


- (void)runSend{
	NSAutoreleasePool* pool  = [[NSAutoreleasePool alloc] init];
	[self retain];
	[self autorelease];
	NSObject<HServerDelegate>* d = (NSObject<HServerDelegate>*)_delegate;
    [d retain];
    [d autorelease];
	NSHTTPURLResponse* response = nil;
    NSError* error = nil;
	NSData* data = [NSURLConnection sendSynchronousRequest:_request returningResponse:&response error:&error];
    if (error) {
        DGLogErrorT(@"HServer", @"error: %@", error);
    }
    self.response = response;
    NSInteger code = response.statusCode/100; 
    
    
    NSString* info = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]; 
    
    NSString* requestBody = [[[NSString alloc] initWithData:_request.HTTPBody encoding:NSUTF8StringEncoding] autorelease];
    DGLogInfoT(@"HServer", @" requestAddr:[%@]%@\n requestBody:%@\n response:%@\n response:%d-%@",_request.HTTPMethod, _request.url,requestBody,_response.allHeaderFields,_response.statusCode,info);
    
    if (info == nil) {
        //简体中文编码转换
        NSStringEncoding strEncode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);  
        info = [[[NSString alloc] initWithData:data encoding:strEncode] autorelease]; 
    }
    SEL selector = @selector(requestFinished:withResult:);
    HSenderHandler handler = _successHandler;
    if (data == nil||code==4||code==5) {
		selector = @selector(requestFailed:withResult:);
        handler = _failedHandler;
	}
    //NSInvocation类的实例用于封装Objective-C消息。一个调用对象中含有一个目标对象、一个方法选择器、以及方法参数。
    //创建NSInvocation对象需要使用NSMethodSignature对象，该对象负责封装与方法参数和返回值有关系的信息。	
	if ([d respondsToSelector:selector]) {
		NSMethodSignature *sig = [d methodSignatureForSelector:selector];		
		NSInvocation* invo = [NSInvocation invocationWithMethodSignature:sig];
		[invo setTarget:d];
		[invo setSelector:selector];
        //requestFinished:(HttpSender*)sender withResult:(id)result;
		[invo setArgument:&self atIndex:2];
		[invo setArgument:&info atIndex:3];
		[invo retainArguments];
		[invo performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:YES];
	}
    
    if (handler) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            _successHandler(self,info);
        });
    }
    
	[pool release];
	return;
}

- (void)sendRequest{	
    if (self.driver == EVENT) {
        self.connection = [NSURLConnection connectionWithRequest:_request delegate:self];
    }else if(self.driver == THREAD){
        NSThread* t = [[NSThread alloc] initWithTarget:self selector:@selector(runSend) object:nil];
        [t start];
        [t release];
    }
}

- (void)dealloc{
	[_request release];
    [_connection release];
    [_response release];
    [_successHandler release];
    [_failedHandler release];
	[super dealloc];
}

- (void)setSuccessHandler:(HSenderHandler)successHandler{
    [_successHandler autorelease];
    _successHandler = [successHandler copy];
    if (_failedHandler || _successHandler) {
        _delegate = nil;
    }
}

- (void)setFailedHandler:(HSenderHandler)failedHandler{
    [_failedHandler autorelease];
    _failedHandler = [failedHandler copy];
    if (_failedHandler || _successHandler) {
        _delegate = nil;
    }
}

- (void)setDelegate:(id<HServerDelegate>)delegate{
    _delegate = delegate;
    if (_delegate) {
        _successHandler = NULL;
        _failedHandler = NULL;
    }
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    self.response = (NSHTTPURLResponse*)response;
    _data = [[NSMutableData data] retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [_data release];
    _data = nil;
    self.connection = nil;
    
    NSString* requestBody = [[[NSString alloc] initWithData:_request.HTTPBody encoding:NSUTF8StringEncoding] autorelease];
    DGLogInfoT(@"HServer", @" requestAddr:[%@]%@\n requestBody:%@\n response:%@\n response:%d-%@",_request.HTTPMethod, _request.url,requestBody,_response.allHeaderFields,_response.statusCode,@"NULL");
    
    [_delegate requestFailed:self withResult:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSString* info = [[[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding] autorelease]; 
    
    if (info == nil) {
        //简体中文编码转换
        NSStringEncoding strEncode = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);  
        info = [[[NSString alloc] initWithData:_data encoding:strEncode] autorelease]; 
    }
    
    NSString* requestBody = [[[NSString alloc] initWithData:_request.HTTPBody encoding:NSUTF8StringEncoding] autorelease];
    DGLogInfoT(@"HServer", @" requestAddr:[%@]%@\n requestBody:%@\n response:%@\n response:%d-%@",_request.HTTPMethod, _request.url,requestBody,_response.allHeaderFields,_response.statusCode,info);
    
    [_data release];
    _data = nil;
    self.connection = nil;
    
    NSInteger code = _response.statusCode/100; 
    
    if (code == 4 || code == 5) {
        if (_delegate) {
            [_delegate requestFailed:self withResult:info];
        }
        if (_failedHandler) {
            _failedHandler(self,info);
        }
    }else{
        if (_delegate) {
            [_delegate requestFinished:self withResult:info];
        }
        if (_successHandler) {
            _successHandler(self,info);
        }
    }
    
}



@end

@interface HttpRequest(Private)

- (void)generate;

@end

@implementation HttpRequest

@synthesize url = _url;
@synthesize params = _params;
@synthesize oData = _oData;
@synthesize subData = _subData;
@synthesize files = _files;

- (id)init{
    if ([super init]) {
        self.timeoutInterval = TIME_OUT_DEFAULT;
        _params = [[NSMutableDictionary alloc] initWithCapacity:5];
        [self generate];
    }
    return self;
}

- (id)initWithURL:(NSURL *)URL{
    if ([super initWithURL:URL]) {
        self.timeoutInterval = TIME_OUT_DEFAULT;
        _url = [URL retain];
        _params = [[NSMutableDictionary alloc] initWithCapacity:5];
        [self generate];
    }
    return self;
}

- (id)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval{
    if ([super initWithURL:URL cachePolicy:cachePolicy timeoutInterval:timeoutInterval]) {
        self.timeoutInterval = TIME_OUT_DEFAULT;
        _url = [URL retain];
        _params = [[NSMutableDictionary alloc] initWithCapacity:5];
        [self generate];
    }
    return self;
}

- (void)setUrl:(NSURL *)url{
    if (url != _url) {
        self.timeoutInterval = TIME_OUT_DEFAULT;
        [_url release];
        _url = [url retain];
        [self generate];
    }
}


- (void)setParams:(NSDictionary *)params{
    if (_params != params) {
        [_params release];
        _params = params;
        [_params retain];
        [self generate];
    }
}

- (void)setHTTPMethod:(NSString *)method{
    [super setHTTPMethod:method];
    [self generate];
}

- (void)addFile:(NSString*)name fileName:(NSString*)fileName type:(NSString*)type fileData:(NSData*)data{
    if (_files == nil) {
        self.files = [NSMutableArray arrayWithCapacity:2];
    }
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          name,@"name",
                          fileName,@"fileName",
                          type,@"type",
                          data,@"data",
                          nil];
    [self.files addObject:dict];
    [self generate];
}

//如果是get url后面加上?+para 如果是post 就在body里加para
- (void)generate{
    if (_url == nil) {
        return;
    }
    NSString* str = [_url absoluteString];
    NSRange range = [str rangeOfString:@"?"];
    if (range.length>0) {
        str = [str substringToIndex:range.location];
    }

    NSString* paramString = @"";
    NSMutableData* postBody = nil;
    NSString* contentType = @"text/html";
    //上传
    if (_files!=nil&&[_files count]>0) {
        postBody = [NSMutableData data];
        NSString* stringBoundary = [NSString stringWithString:@"--------0xKh3TmL5bOuNdAr4Y"];
        contentType = [NSString stringWithFormat:@"multipart/form-data;boundary=%@",stringBoundary];
        //[postBody appendData:[[NSString stringWithString:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        BOOL flag = NO;
        for (NSString* key in [_params allKeys]) {
            if (!flag) {
                //\r\n换行
                [postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
                flag = YES;
            }else{
                [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
            }
            
            [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
            
            [postBody appendData:[[NSString stringWithString:[_params objectForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]]; 
        }
        
        for (NSDictionary* dict in _files) {            
            [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];            
            [postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",[dict objectForKey:@"name"],[dict objectForKey:@"fileName"]] dataUsingEncoding:NSUTF8StringEncoding]];            
            [postBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n",[dict objectForKey:@"type"]] dataUsingEncoding:NSUTF8StringEncoding]];             
            [postBody appendData:[dict objectForKey:@"data"]];
        }
        [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

    }else{
        BOOL flag = NO;
        for (NSString* key in [_params allKeys]) {
            NSString* value = [_params objectForKey:key];
            if (flag) {
                paramString = [paramString stringByAppendingString:@"&"];
            }else {
                flag = YES;
            }
            paramString = [paramString stringByAppendingFormat:@"%@=%@",key,[value URLEncodeString]];
            //paramString = [paramString stringByAppendingFormat:@"%@=%@",key,value];
        }
    }
    if (postBody!=nil) {
        [self addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [self setHTTPBody:postBody];
        if ([self.HTTPMethod isEqualToString:@"GET"]) {
            self.HTTPMethod = @"POST";
        }
    }else{
        if ([self.HTTPMethod isEqualToString:@"GET"] && [paramString length]>0) {
            str = [NSString stringWithFormat:@"%@?%@",str,paramString];
        }else{
            NSData* requestData = [paramString dataUsingEncoding:NSUTF8StringEncoding];
            [self setHTTPBody:requestData];
        }
    }
    [_url release];
    //str = [str URLEncodeString];
    _url = [[NSURL URLWithString:str] retain];
    self.URL = [NSURL URLWithString:str];
}

- (void)dealloc{
    [_oData release];
    [_subData release];
    [_url release];
    [_files release];
    [super dealloc];
}

@end


@implementation HServer

+ (HServer*)instance{
	if (hServer == nil) {
		hServer = [[HServer alloc] init];
	}
	return hServer;
}

- (HttpSender*)sendRequest:(HttpRequest*)request delegate:(id<HServerDelegate>)delegate{
	HttpSender* sender = [[HttpSender alloc] init];
	sender.request = request;
	sender.delegate = delegate;
	[sender sendRequest];
	[sender autorelease];
	return sender;
}

@end

@implementation NSString (URLEncoding)
//pass special characters properly via URL to database
- (NSString*)URLEncodeString{
    //NSString* result = (NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,(CFStringRef)self,NULL,NULL, kCFStringEncodingUTF8);
    //[result autorelease];
    NSString *result = (NSString *)   
    CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,  
                                            (CFStringRef)self,  
                                            NULL,  
                                            (CFStringRef)@"!*'();:@&=+$,/?%#[]",  
                                            kCFStringEncodingUTF8);  
    return result;
}

- (NSString*)URLDecodeString{
    //NSString* result = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)self, NULL, kCFStringEncodingUTF8);
    //[result autorelease];
    NSMutableString *result = [NSMutableString stringWithString:self];  
    [result replaceOccurrencesOfString:@"+"  
                            withString:@" "  
                               options:NSLiteralSearch  
                                 range:NSMakeRange(0, [result length])];  
    return [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
@end
