//
//  LCAFNManager.h
//  LCNetWork
//
//  Created by cheshili5 on 2017/12/6.
//  Copyright © 2017年 cheshili5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AFNetworking.h>

extern  NSString * const LCAFNetworkReachabilityNotificationKey;
extern  NSString * const LCAFNetworkReachabilityStatusKey;

//typedef void(^LCRequestSuccess)(id result);
//typedef void(^LCRequestFailure)(NSError *error);
typedef NS_ENUM(NSInteger, HTTPResponseStyle){
    AFHTTPResponse, //返回的类型data
    AFJSONResponse, //json
    AFXMLResponse   //xml
};

typedef NS_ENUM(NSInteger, RequsetBodyStyle){
    RequsetBodyHttp,
    RequsetBodyJSON
};

typedef NS_ENUM(NSInteger, LCAFNetworkReachabilityStatus){
    LCAFNetworkReachabilityStatusUnknown          = -1,
    LCAFNetworkReachabilityStatusNotReachable     = 0,
    LCAFNetworkReachabilityStatusReachableViaWWAN = 1,
    LCAFNetworkReachabilityStatusReachableViaWiFi = 2,
};


@interface LCAFNManager : NSObject


/**
 网络是否可用
 */
@property (nonatomic, assign, readonly) BOOL isNetWorkReachable;

/**
 当前的网络状态
 AFNetworkReachabilityStatusUnknown          = -1,
 AFNetworkReachabilityStatusNotReachable     = 0,
 AFNetworkReachabilityStatusReachableViaWWAN = 1,
 AFNetworkReachabilityStatusReachableViaWiFi = 2,
 */
@property(nonatomic,assign)LCAFNetworkReachabilityStatus networkStatus;


+ (instancetype)sharedInstance;


/**默认返回dic
 *  网络请求get
 *  @param url     请求url
 *  @param success 成功调用的Block
 *  @param failure 失败调用的Block
 */
- (NSNumber *)getWithUrl:(NSString *)url body:(id)body success:(void(^)(id result))success failure:(void(^)(NSError *error))failure;



/**默认返回dic
 *  网络请求post
 *  @param url       请求url
 *  @param body      网络请求携带的Body
 *  @param success   成功调用的Block
 *  @param failure   失败调用的Block
 */
- (NSNumber *)postWithUrl:(NSString *)url body:(id)body success:(void(^)(id result))success failure:(void(^)(NSError *error))failure;


/**
 *  网络请求get
 *
 *  @param url     请求url
 *  @param body    网络请求携带的Body
 *  @param responseStyle   请求返回的数据的格式
 *  @param success 成功调用的Block
 *  @param failure 失败调用的Block
 */
- (NSNumber *)get:(NSString *)url body:(id)body responseStyle:(HTTPResponseStyle)responseStyle success:(void(^)(id result))success failure:(void(^)(NSError *error))failure;



/**
 *  网络请求post
 *
 *  @param url       请求url
 *  @param body      网络请求携带的Body
 *  @param responseStyle     请求返回的数据的格式
 *  @param headers       请求头
 *  @param success   成功调用的Block
 *  @param failure   失败调用的Block
 */
- (NSNumber *)post:(NSString *)url body:(id)body responseStyle:(HTTPResponseStyle)responseStyle requestHeader:(NSDictionary *)headers success:(void(^)(id result))success failure:(void(^)(NSError *error))failure;



/**
 上传图片接口 -- 可以传duo张图片

 @param url url
 @param body body
 @param images 图片数字
 @param success success
 @param failure failure
 @param progress progress
 */
- (NSNumber *)post:(NSString *)url body:(id)body name:(NSString *)name images:(NSArray *)images success:(void(^)(id result))success failure:(void(^)(NSError *error))failure progress:(void (^)(NSProgress *uploadProgress))progress;


/**
 上传文件接口 封装之后的

 @param url url
 @param body body
 @param data 上传文件
 @param name 名字
 @param fileName 文件名字
 @param mimeType mimeType
 @param success success
 @param failure failure
 @param progress progress 进度
 */
- (NSNumber *)uploadFile:(NSString *)url body:(id)body data:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType success:(void(^)(id result))success failure:(void(^)(NSError *error))failure progress:(void (^)(NSProgress *uploadProgress))progress;



/**
 直接使用afn上传接口

 @param url url description
 @param body body description
 @param block block description
 @param progress progress description
 @param success success description
 @param failure failure description
 @return return value description
 */
- (NSNumber *)AFNuploadFile:(NSString *)url body:(id)body
  constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> formData))block
                   progress:(nullable void (^)(NSProgress * _Nonnull progress))progress
                    success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                    failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;


/**
 文件下载

 @param url 下载路径
 @param targetPath 目标位置 不传默认为 Documents 文件下
 @param downloadProgressBlock 进度
 @param completionHandler 完成回调
 */
- (NSNumber *)download:(NSString *)url targetPath:(NSString *)targetPath progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock completionHandler:(nullable void (^)(NSURLResponse *response, NSURL * _Nullable filePath, NSError * _Nullable error))completionHandler;

/**
   开启网络检测 会发通知 LCAFNetworkReachabilityNotificationKey
 
 LCAFNetworkReachabilityStatusKey
 
 LCAFNetworkReachabilityStatusUnknown          = -1,
 LCAFNetworkReachabilityStatusNotReachable     = 0,
 LCAFNetworkReachabilityStatusReachableViaWWAN = 1,
 LCAFNetworkReachabilityStatusReachableViaWiFi = 2,
 */
- (void)openAFNetworkReachability;

/**
 开启网络检测 带回调block
 
 LCAFNetworkReachabilityStatusUnknown          = -1,
 LCAFNetworkReachabilityStatusNotReachable     = 0,
 LCAFNetworkReachabilityStatusReachableViaWWAN = 1,
 LCAFNetworkReachabilityStatusReachableViaWiFi = 2,
 */
- (void)openAFNetworkReachabilityWithBlock:(void (^)(LCAFNetworkReachabilityStatus status))block;


/**
 取消请求
 @param requestID requestID
 */
- (void)cancelRequestWithRequestID:(NSNumber *)requestID;
- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList;



@end
