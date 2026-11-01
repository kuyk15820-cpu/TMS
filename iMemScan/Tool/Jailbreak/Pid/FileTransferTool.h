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
 * @param targetBundleID Bundle ID ของแอปเป้าหมาย (เช่น "com.dts.freefireth")
 * @return บูลินบอกสถานะว่าสร้างและบันทึกไฟล์สำเร็จหรือไม่
 */
+ (BOOL)createLocalConfigInTargetApp:(NSString *)targetBundleID;

/**
 * ลบไฟล์ localConfig.json ออกจากโฟลเดอร์ Documents ของแอปเป้าหมาย (สำหรับใช้กับ Switch เปิด-ปิด)
 * @param targetBundleID Bundle ID ของแอปเป้าหมาย (เช่น "com.dts.freefireth")
 * @return บูลินบอกสถานะว่าลบไฟล์สำเร็จหรือไม่
 */
+ (BOOL)removeLocalConfigFromTargetApp:(NSString *)targetBundleID;

end

NS_ASSUME_NONNULL_END
