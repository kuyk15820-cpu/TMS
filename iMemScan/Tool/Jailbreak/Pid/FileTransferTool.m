//
//  FileTransferTool.m
//  iMemScan
//
//  Created by Custom on 2026.
//

#import "FileTransferTool.h"

@implementation FileTransferTool

+ (BOOL)createLocalConfigInTargetApp:(NSString *)targetBundleID {
    // 1. ค้นหา Data Container Path ของแอปเป้าหมายผ่าน LSApplicationWorkspace
    NSString *targetDocumentsPath = nil;
    
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    if (workspaceClass) {
        id workspace = [workspaceClass performSelector:NSSelectorFromString(@"defaultWorkspace")];
        NSArray *installedApps = [workspace performSelector:NSSelectorFromString(@"allInstalledApplications")];
        
        for (id app in installedApps) {
            NSString *appBundleID = [app performSelector:NSSelectorFromString(@"applicationIdentifier")];
            if ([appBundleID.lowercaseString isEqualToString:targetBundleID.lowercaseString]) {
                NSURL *dataContainerURL = [app performSelector:NSSelectorFromString(@"dataContainerURL")];
                if (dataContainerURL) {
                    targetDocumentsPath = [[dataContainerURL path] stringByAppendingPathComponent:@"Documents"];
                }
                break;
            }
        }
    }
    
    if (!targetDocumentsPath) {
        NSLog(@"[FileTransferTool] Error: Could not find Data Container for bundleID: %@", targetBundleID);
        return NO;
    }
    
    // 2. ตรวจสอบว่าโฟลเดอร์ Documents ปลายทางมีอยู่จริงไหม ถ้าไม่มีให้สร้าง
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:targetDocumentsPath]) {
        NSError *dirError = nil;
        [fileManager createDirectoryAtPath:targetDocumentsPath withIntermediateDirectories:YES attributes:nil error:&dirError];
        if (dirError) {
            NSLog(@"[FileTransferTool] Error creating Documents dir: %@", dirError.localizedDescription);
            return NO;
        }
    }
    
    // 3. กำหนดชื่อไฟล์และเนื้อหา JSON ที่ต้องการสร้าง
    NSString *fileName = @"localConfig.json";
    NSString *destinationPath = [targetDocumentsPath stringByAppendingPathComponent:fileName];
    
    // เนื้อหา JSON ตามที่คุณต้องการ
    NSDictionary *jsonDict = @{
        @"testCodePatch": @YES,
        @"resetGuest": @YES
    };
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&jsonError];
    
    if (!jsonData || jsonError) {
        NSLog(@"[FileTransferTool] Error: Failed to serialize JSON: %@", jsonError.localizedDescription);
        return NO;
    }
    
    // 4. เขียนไฟล์ลงไปยัง Documents ของแอปเป้าหมายทันที
    BOOL success = [jsonData writeToFile:destinationPath atomically:YES];
    if (!success) {
        NSLog(@"[FileTransferTool] Error: Failed to write file to %@", destinationPath);
        return NO;
    }
    
    NSLog(@"[FileTransferTool] Success: Created %@ at %@", fileName, destinationPath);
    return YES;
}

+ (BOOL)removeLocalConfigFromTargetApp:(NSString *)targetBundleID {
    // 1. ค้นหา Data Container Path ของแอปเป้าหมายผ่าน LSApplicationWorkspace
    NSString *targetDocumentsPath = nil;
    
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    if (workspaceClass) {
        id workspace = [workspaceClass performSelector:NSSelectorFromString(@"defaultWorkspace")];
        NSArray *installedApps = [workspace performSelector:NSSelectorFromString(@"allInstalledApplications")];
        
        for (id app in installedApps) {
            NSString *appBundleID = [app performSelector:NSSelectorFromString(@"applicationIdentifier")];
            if ([appBundleID.lowercaseString isEqualToString:targetBundleID.lowercaseString]) {
                NSURL *dataContainerURL = [app performSelector:NSSelectorFromString(@"dataContainerURL")];
                if (dataContainerURL) {
                    targetDocumentsPath = [[dataContainerURL path] stringByAppendingPathComponent:@"Documents"];
                }
                break;
            }
        }
    }
    
    if (!targetDocumentsPath) {
        NSLog(@"[FileTransferTool] Error: Could not find Data Container for bundleID: %@", targetBundleID);
        return NO;
    }
    
    // 2. ระบุ path ของไฟล์ localConfig.json ที่ต้องการลบ
    NSString *filePath = [targetDocumentsPath stringByAppendingPathComponent:@"localConfig.json"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 3. ตรวจสอบว่ามีไฟล์อยู่จริงไหม ถ้ามีให้ทำการลบ
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error = nil;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success) {
            NSLog(@"[FileTransferTool] Error: Failed to delete file: %@", error.localizedDescription);
            return NO;
        }
        NSLog(@"[FileTransferTool] Success: Removed file at %@", filePath);
        return YES;
    }
    
    // ถ้าไม่มีไฟล์อยู่แล้ว ถือว่าเคลียร์สถานะสำเร็จ
    return YES;
}

@end
