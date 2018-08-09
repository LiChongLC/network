//
//  NSDictionary+LCExtension.h
//  LCNetWork
//
//  Created by cheshili5 on 2017/12/8.
//  Copyright © 2017年 cheshili5. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (LCExtension)

+ (id)lc_deleteNull:(id)myObj; //

+ (NSString*)lc_dicDataTOjsonString:(id)object; //

+ (NSDictionary *)lc_dictionaryWithJsonString:(NSString *)jsonString; //

@end
