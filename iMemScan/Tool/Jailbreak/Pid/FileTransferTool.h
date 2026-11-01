//
//  FileTransferTool.h
//  iMemScan
//
//  Created by Custom on 2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileTransferTool : NSObject

+ (BOOL)createLocalConfigInTargetApp:(NSString *)targetBundleID;
+ (BOOL)removeLocalConfigFromTargetApp:(NSString *)targetBundleID;

/**
 * ตรวจสอบว่ามีไฟล์ localConfig.json อยู่ในโฟลเดอร์ Documents ของแอปเป้าหมายหรือไม่
 * @param targetBundleID Bundle ID ของแอปเป้าหมาย
 * @return บูลินบอกสถานะว่ามีไฟล์อยู่จริงหรือไม่
 */
+ (BOOL)isLocalConfigExistInTargetApp:(NSString *)targetBundleID;

@end

NS_ASSUME_NONNULL_END
