//
//  LCAFNManager.m
//  LCNetWork
//
//  Created by cheshili5 on 2017/12/6.
//  Copyright © 2017年 cheshili5. All rights reserved.
//

#import "LCAFNManager.h"
#import "NSDictionary+LCExtension.h"
#import <CoreFoundation/CoreFoundation.h>

NSString * const LCAFNetworkReachabilityNotificationKey = @"AFNetworkReachabilityKey";
NSString * const LCAFNetworkReachabilityStatusKey = @"LCAFNetworkReachabilityStatus";


@interface LCAFNManager ()

@property (nonatomic, strong) NSMutableDictionary *dispatchTable;
@property (nonatomic, strong) NSNumber *recordedRequestId;

@end

@implementation LCAFNManager
#pragma mark - getters and setters
- (NSMutableDictionary *)dispatchTable
{
    if (_dispatchTable == nil) {
        _dispatchTable = [[NSMutableDictionary alloc] init];
    }
    return _dispatchTable;
}
#pragma mark - life cycle
+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static LCAFNManager *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[LCAFNManager alloc] init];
    });
    return sharedInstance;
}

-(AFHTTPSessionManager *)afnManagerFrome:(HTTPResponseStyle)style bodyStyle:(RequsetBodyStyle)bodyStyle{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    
    switch (style) {
        case AFHTTPResponse:
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
        case AFJSONResponse:
        {
            AFJSONResponseSerializer *response = [AFJSONResponseSerializer serializer];
            //            response.removesKeysWithNullValues = YES;
            manager.responseSerializer = response;
        }
            break;
        case AFXMLResponse:
            manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
            break;
        default:
            manager.responseSerializer = [AFHTTPResponseSerializer serializer];
            break;
    }
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/plain", nil]];
    if (bodyStyle) {
        switch (bodyStyle) {
            case RequsetBodyHttp:
                manager.requestSerializer = [AFHTTPRequestSerializer serializer];
                break;
            case RequsetBodyJSON:
                manager.requestSerializer = [AFJSONRequestSerializer serializer];
                break;
            default:
                break;
        }
    }
    return manager;
}



/**默认返回data
 *  网络请求get
 *  @param url     请求url
 *  @param success 成功调用的Block
 *  @param failure 失败调用的Block
 */
- (NSNumber *)getWithUrl:(NSString *)url body:(id)body success:(void(^)(id result))success failure:(void(^)(NSError *error))failure{
    return [self get:url body:body responseStyle:AFJSONResponse success:success failure:failure];
}



/**默认返回data
 *  网络请求post
 *  @param url       请求url
 *  @param body      网络请求携带的Body
 *  @param success   成功调用的Block
 *  @param failure   失败调用的Block
 */
- (NSNumber *)postWithUrl:(NSString *)url body:(id)body success:(void(^)(id result))success failure:(void(^)(NSError *error))failure{
    return  [self post:url body:body responseStyle:AFJSONResponse requestHeader:nil success:success failure:failure];
}



/**
 *  网络请求get
 *
 *  @param url     请求url
 *  @param body    网络请求携带的Body
 *  @param responseStyle   请求返回的数据的格式
 *  @param success 成功调用的Block
 *  @param failure 失败调用的Block
 */
- (NSNumber *)get:(NSString *)url body:(id)body responseStyle:(HTTPResponseStyle)responseStyle success:(void(^)(id result))success failure:(void(^)(NSError *error))failure{
    
    AFHTTPSessionManager *manager = [self afnManagerFrome:responseStyle bodyStyle:0];
    NSURLSessionDataTask *task =  [manager GET:url parameters:body progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            responseObject = [NSDictionary lc_deleteNull:responseObject];
        }
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        failure(error);
    }];
    
    NSNumber *requestId = @([task taskIdentifier]);
    self.dispatchTable[requestId] = task;
    
    return requestId;
}



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
- (NSNumber *)post:(NSString *)url body:(id)body responseStyle:(HTTPResponseStyle)responseStyle requestHeader:(NSDictionary *)headers success:(void(^)(id result))success failure:(void(^)(NSError *error))failure{
    
    AFHTTPSessionManager *manager = [self afnManagerFrome:responseStyle bodyStyle:0];
    
    if (headers) {
        for (NSString *key in headers.allKeys) {
            [manager.requestSerializer setValue:headers[key] forHTTPHeaderField:key];
        }
    }
    // 跑到这里的block的时候，就已经是主线程了。
    __block NSURLSessionDataTask *task = nil;
    task =  [manager POST:url parameters:body progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            responseObject = [NSDictionary lc_deleteNull:responseObject];
            
        }
        success(responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        failure(error);
        
    }];
    NSNumber *requestId = @([task taskIdentifier]);
    self.dispatchTable[requestId] = task;
    
    return requestId;
}



- (NSNumber *)post:(NSString *)url body:(id)body name:(NSString *)name images:(NSArray *)images success:(void(^)(id result))success failure:(void(^)(NSError *error))failure progress:(void (^)(NSProgress *uploadProgress))progress{
    
    if (images == nil || images.count == 0) {
        NSError *error = [[NSError alloc] initWithDomain:@"images cant be nil" code:-519 userInfo:nil];
        failure(error);
    }
    
    AFHTTPSessionManager *manager = [self afnManagerFrome:AFJSONResponse bodyStyle:0];
    // 跑到这里的block的时候，就已经是主线程了。
    __block NSURLSessionDataTask *task = nil;
     task =  [manager POST:url parameters:body constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        for (UIImage *image in images) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd-hh:mm:ss";
            NSString *fname = [formatter stringFromDate:[NSDate date]];
            
            NSData *data = UIImageJPEGRepresentation(image, 1.0);
            if (data.length>1024*1024) {//1M以及以上
                
                data=UIImageJPEGRepresentation(image, 0.1);
                
            }else if (data.length>512*1024) {
                //0.5M-1M
                data=UIImageJPEGRepresentation(image, 0.5);
                
            }else{
                //0.25M-0.5M
                data=UIImageJPEGRepresentation(image, 0.8);
                
            }
            //            NSData *imagedate = UIImageJPEGRepresentation(image, 0.3);
            
            NSString *fileName = [NSString stringWithFormat:@"%@.png", fname];
            [formData appendPartWithFileData:data name:name fileName:fileName mimeType:@"image/png"];
            
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progress)progress(uploadProgress);
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        success(responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        failure(error);
        
    }];
    
    NSNumber *requestId = @([task taskIdentifier]);
    self.dispatchTable[requestId] = task;
    
    return requestId;
    
}
- (NSNumber *)uploadFile:(NSString *)url body:(id)body data:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType success:(void(^)(id result))success failure:(void(^)(NSError *error))failure progress:(void (^)(NSProgress *uploadProgress))progress{
    
    AFHTTPSessionManager *manager = [self afnManagerFrome:AFJSONResponse bodyStyle:0];
    // 跑到这里的block的时候，就已经是主线程了。
    __block NSURLSessionDataTask *task = nil;
    task =  [manager POST:url parameters:body constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {

        /* 上传数据拼接 */
        [formData appendPartWithFileData:data name:name fileName:fileName mimeType:mimeType];
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        if (progress)progress(uploadProgress);
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        success(responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        failure(error);

    }];
    
    
    NSNumber *requestId = @([task taskIdentifier]);
    self.dispatchTable[requestId] = task;
    
    return requestId;
    
}
- (NSNumber *)AFNuploadFile:(NSString *)url body:(id)body
  constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> formData))block
                   progress:(nullable void (^)(NSProgress * _Nonnull progress))progress
                    success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                    failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure{
    
    AFHTTPSessionManager *manager = [self afnManagerFrome:AFJSONResponse bodyStyle:0];
    // 跑到这里的block的时候，就已经是主线程了。
    __block NSURLSessionDataTask *task = nil;
    task =  [manager POST:url parameters:body constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        block(formData);
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        progress(uploadProgress);
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        success(task,responseObject);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        failure(task,error);
        
    }];
    
    
    NSNumber *requestId = @([task taskIdentifier]);
    self.dispatchTable[requestId] = task;
    
    return requestId;
    
}
- (NSNumber *)download:(NSString *)url targetPath:(NSString *)targetPath progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgressBlock completionHandler:(nullable void (^)(NSURLResponse *response, NSURL * _Nullable filePath, NSError * _Nullable error))completionHandler{
    
    
    AFHTTPSessionManager *manager = [self afnManagerFrome:AFJSONResponse bodyStyle:0];


    /* 下载地址 */
    NSURL *downloadurl = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadurl];
    
    NSString *filePath = targetPath;
    if (filePath == nil || [filePath isEqualToString:@""]) {
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        filePath = [path stringByAppendingPathComponent:url.lastPathComponent];
    }
    
    // 跑到这里的block的时候，就已经是主线程了。
    __block NSURLSessionDownloadTask *task = nil;
     task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        if (downloadProgressBlock)downloadProgressBlock(downloadProgress);

    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        /* 设定下载到的位置 */
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [self removeRequestWithRequestID:@([task taskIdentifier])];
        if (completionHandler)completionHandler(response,filePath,error);

    }];
    [task resume];

    NSNumber *requestId = @([task taskIdentifier]);
    self.dispatchTable[requestId] = task;
    
    return requestId;
    
}
//压缩图片
-(NSData *)getImageData:(UIImage *)image{
    NSData *imagedate = UIImageJPEGRepresentation(image, 0.3);
    
    UIImage *resimage = [UIImage imageWithData:imagedate];
    
    while (([imagedate length]/1000) > 500 ) {
        resimage = [UIImage imageWithData:imagedate];
        imagedate = UIImageJPEGRepresentation(resimage, 0.9);
        
    }
    //NSLog(@"%ld",imagedate.length);
    return imagedate;
}

//网络检测
- (void)openAFNetworkReachability {
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [[NSNotificationCenter defaultCenter] postNotificationName:LCAFNetworkReachabilityNotificationKey object:@{LCAFNetworkReachabilityStatusKey:@(status)}];
    }];
    [manager startMonitoring];
}
- (void)openAFNetworkReachabilityWithBlock:(void (^)(LCAFNetworkReachabilityStatus status))block{
    AFNetworkReachabilityManager *manager = [AFNetworkReachabilityManager sharedManager];
    [manager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        block((LCAFNetworkReachabilityStatus)status);
    }];
    [manager startMonitoring];
}

-(void)getSmallImages:(NSArray *)imageArray complite:(void(^)(NSArray *imageArray))complite{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray *imageArr = [NSMutableArray array];
        for (UIImage *image in imageArray) {
            NSData *imageData = UIImagePNGRepresentation(image);
            NSData *upData;
            if (imageData.length > 500*1024) {
                upData = UIImageJPEGRepresentation(image, 500*1024/imageData.length);
            }else{
                upData = imageData;
            }
            [imageArr addObject:upData];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complite)complite(imageArr);
                });
    });

}


-(void)sendError:(NSError *)error url:(NSString *)url body:(NSDictionary *)dic task:(NSURLSessionDataTask *) task{
    
    
    AFHTTPSessionManager *outmanager = [self afnManagerFrome:AFHTTPResponse bodyStyle:RequsetBodyHttp];
    
    [outmanager POST:url parameters:dic progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *temp = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSMutableDictionary *paras = [NSMutableDictionary dictionary];
        //        [paras setObject:CSL_TOKEN forKey:@"WToken"];
        [paras setObject:url forKey:@"Url"];
        [paras setObject:[NSDictionary lc_dicDataTOjsonString:dic] forKey:@"PostData"];
        NSString *outputStr = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                    (CFStringRef)temp,
                                                                                                    NULL,
                                                                                                    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                    kCFStringEncodingUTF8));
        
        
        [paras setObject:outputStr forKey:@"LogCont"];
        
        //        NSString *urlStr = [NSString stringWithFormat:@"%@League/StoreService/InsertErrLog",MainSeverce];
        
//        AFHTTPSessionManager *manager = [self afnManagerFrome:AFJSONResponse bodyStyle:RequsetBodyHttp];
//
        //        [manager POST:urlStr parameters:paras progress:^(NSProgress * _Nonnull uploadProgress) {
        //
        //        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //
        //        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //
        //        }];
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
    
    
    
    //    NSString *temp = [NSString stringWithFormat:@"Date = %@ --- error = %@",[NSDate dateFromTimeinterval:[NSDate date].timeIntervalSince1970],error];
    
    
    
    
}
- (void)cancelRequestWithRequestID:(NSNumber *)requestID
{
    NSURLSessionDataTask *requestOperation = self.dispatchTable[requestID];
    [requestOperation cancel];
    [self.dispatchTable removeObjectForKey:requestID];
}

- (void)cancelRequestWithRequestIDList:(NSArray *)requestIDList
{
    for (NSNumber *requestId in requestIDList) {
        [self cancelRequestWithRequestID:requestId];
    }
}
- (void)removeRequestWithRequestID:(NSNumber *)requestID{
    [self.dispatchTable removeObjectForKey:requestID];
}
- (BOOL)isNetWorkReachable
{
    if ([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus == AFNetworkReachabilityStatusUnknown) {
        return YES;
    } else {
        return [[AFNetworkReachabilityManager sharedManager] isReachable];
    }
}
-(LCAFNetworkReachabilityStatus)networkStatus{
    return (LCAFNetworkReachabilityStatus)[AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
}
@end


