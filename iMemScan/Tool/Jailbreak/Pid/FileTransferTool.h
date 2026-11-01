//
//  FileTransferTool.h
//  iMemScan
//
//  Created by Custom on 2026.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileTransferTool : NSObject

/**
 * สร้างไฟล์ localConfig.json พร้อมเนื้อหา JSON อัตโนมัติ ไปวางไว้ที่โฟลเดอร์ Documents ของแอปเป้าหมาย
 */
+ (BOOL)createLocalConfigInTargetApp:(NSString *)targetBundleID;

/**
 * ลบไฟล์ localConfig.json ออกจากโฟลเดอร์ Documents ของแอปเป้าหมาย
 */
+ (BOOL)removeLocalConfigFromTargetApp:(NSString *)targetBundleID;

/**
 * ตรวจสอบว่ามีไฟล์ localConfig.json อยู่ในโฟลเดอร์ Documents ของแอปเป้าหมายหรือไม่
 */
+ (BOOL)isLocalConfigExistInTargetApp:(NSString *)targetBundleID;

@end

NS_ASSUME_NONNULL_END
