//
//  HServer.h
//  Signer
//
//  Created by wangchao on 11-6-14.
//  Copyright 2011 bupt. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TIME_OUT_DEFAULT 10

@class HttpSender;
@class HttpRequest;

/**
 * @brief HttpSender的委托，当网络请求返回或失败时被调用
 */

@protocol HServerDelegate

/**
 * 网络请求成功时调用
 * @param sender 发送请求的sender
 * @param result 请求返回的内容
 */

- (void)requestFinished:(HttpSender*)sender withResult:(id)result;

/**
 * 网络请求失败时调用
 * @param sender 发送请求的sender
 * @param result 请求返回的内容（大部分为空）
 */

- (void)requestFailed:(HttpSender*)sender withResult:(id)result;

@end

/**
 * @brief 网络请求的发送者
 * 执行网络请求的类，当进行网络请求时,HttpSender会新开一个线程来执行异步的网络操作，网络请求完成后，调用delegate的相应方法
 */

typedef enum {
    THREAD = 1,
    EVENT = 2
}HsenderDriver;

typedef void (^HSenderHandler)(HttpSender*,id);

@interface HttpSender : NSObject{
    HsenderDriver _driver;
	HttpRequest* _request;
    NSURLConnection* _connection;
    NSHTTPURLResponse* _response;
	id<HServerDelegate> _delegate;
    NSMutableData* _data;
    
    HSenderHandler _successHandler;
    HSenderHandler _failedHandler;
}

@property (nonatomic,assign) HsenderDriver driver;
@property (nonatomic,retain) NSURLConnection* connection;
@property (nonatomic,retain) HttpRequest* request;/**<网络请求的request*/
@property (nonatomic,assign) id<HServerDelegate> delegate;/**<委托*/
@property (nonatomic,retain) NSHTTPURLResponse* response;/**<返回的结果*/

@property (nonatomic,copy) HSenderHandler successHandler;
@property (nonatomic,copy) HSenderHandler failedHandler;


- (void)sendRequest;

@end

/**
 * @brief http请求类
 * 继承NSMutableURLRequest，自定义的Http请求
 */


@interface HttpRequest : NSMutableURLRequest{
    NSDictionary* _params;
    NSURL* _url;
    NSObject* _oData;
    NSObject* _subData;
    NSMutableArray* _files;//upload
}
@property (nonatomic,retain) NSObject* oData; /**<附带的数据，用来标识不同的request*/
@property (nonatomic,retain) NSObject* subData;/**<附带的从数据*/
@property (nonatomic,retain) NSDictionary* params;/**<请求的参数 key和value与请求参数的key value对应*/
@property (nonatomic,retain) NSURL* url;/**<请求的URL*/
@property (nonatomic,retain) NSMutableArray* files;/**<发送的文件*/
/**
 * 向请求添加一个文件
 * @param name 文件对应的表单的名字
 * @param fileName 文件的文件名
 * @param type 文件类型
 * @param 文件的数据
 */
- (void)addFile:(NSString*)name fileName:(NSString*)fileName type:(NSString*)type fileData:(NSData*)data;

@end

/**
 * @brief http请求管理类
 * Http请求的管理类，管理所有的http请求
 */

@interface HServer : NSObject {

}

+ (HServer*)instance;
/**
 * 发送http请求，次函数会立即返回，生成一个HttpSender进行异步的网络请求
 * @param request 请求的request
 * @param delegate 委托
 * @return 返回的HttpSender
 */
- (HttpSender*)sendRequest:(HttpRequest*)request delegate:(id<HServerDelegate>)delegate;
@end

/**
 * @brief NSString的扩展，为其添加网络编码和解码功能
 */

@interface NSString(URLEncoding) 

/**
 * 将自己转化为网络编码
 * @return 网络编码后的字符串
 */
- (NSString*)URLEncodeString;

/**
 * 将网络编码转化为原始字符串
 * @return 解码后的字符串
 */
- (NSString*)URLDecodeString;

@end


