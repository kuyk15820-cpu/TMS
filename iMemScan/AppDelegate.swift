//
//  AppDelegate.swift
//  iMemScan
//
//  Created by yiming on 2021/8/4.
//

import UIKit
import AVFoundation
import MediaPlayer

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var audioPlayer: AVAudioPlayer?
    
    // 用于保存后台下载的completionHandler
    var backgroundSessionCompletionHandler: (() -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Audio()
        overrideUserInterfaceStyle() // 🟢 บังคับใช้ Dark Mode เท่านั้น
        
        // 🟢 สั่งให้ค้นหาและเซ็ต PID อัตโนมัติทันทีที่แอปเปิด (โดยเช็คจากแอปที่กำลังรันอยู่)
        autoSetTargetProcess()
        
        // 🟢 [ทดสอบชั่วคราว] เรียกใช้ FileTransferTool เพื่อสร้างไฟล์ localConfig.json ไปยังแอปเป้าหมาย (เช่น Free Fire)
        testCreateConfigFile()
        
        return true
    }
    
    // 🟢 ฟังก์ชันทดสอบสร้างไฟล์และแสดง Alert แจ้งผลลัพธ์
    func testCreateConfigFile() {
        let targetBundleID = "com.dts.freefireth" // เปลี่ยน Bundle ID ตามต้องการ
        
        // เรียกใช้ Objective-C Tool ที่เราสร้างขึ้น
        let success = FileTransferTool.createLocalConfig(inTargetApp: targetBundleID)
        
        let message = success ? "สร้างไฟล์ localConfig.json สำเร็จ!" : "สร้างไฟล์ไม่สำเร็จ (ไม่พบแอปเป้าหมายหรือติดสิทธิ์)"
        
        // หน่วงเวลาเล็กน้อยเพื่อให้ UI พร้อมแสดง Alert หลังแอปเปิด
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showAlert(title: "ทดสอบการสร้างไฟล์", message: message)
        }
    }
    
    // 🟢 ฟังก์ชันแสดง Alert บนหน้าจอหลัก
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ตกลง", style: .default, handler: nil))
        
        // ค้นหา Window ที่กำลังใช้งานอยู่เพื่อพรีเซนต์ Alert ออกมา
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true, completion: nil)
        }
    }
    
    // 🟢 ฟังก์ชันบังคับให้แอปพลิเคชันแสดงผลเฉพาะ Dark Mode ตลอดการทำงาน
    func overrideUserInterfaceStyle() {
        if #available(iOS 13.0, *) {
            // วนลูปทุก window ของแอปเพื่อบังคับ override เป็น Dark
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        window.overrideUserInterfaceStyle = .dark
                    }
                }
            }
            // เผื่อกรณี UIWindow เริ่มต้น
            window?.overrideUserInterfaceStyle = .dark
        }
    }
    
    // 🟢 ฟังก์ชันค้นหาและตั้งค่า PID อัตโนมัติ
    func autoSetTargetProcess() {
        // ⚠️ ชื่อแอปเป้าหมายเริ่มต้น (สอดคล้องกับค่า Default ใน ScriptManagerViewModel)
        let targetName = "FreeFire"
        let alternateName = "Free Fire"
        
        // ดึงรายการ process ทั้งหมดที่กำลังรันอยู่ผ่าน PidModel
        guard let sections = PidModel.refreshModelArray() as? [[PidModel]] else { return }
        
        for section in sections {
            for model in section {
                let modelName = model.name
                if modelName.localizedCaseInsensitiveContains(targetName) || modelName.localizedCaseInsensitiveContains(alternateName) {
                    if let pidInt = Int32(model.pid) {
                        // เซ็ต PID เข้า VMTool ทันที
                        VMTool.share().setPid(pidInt, name: model.name)
                        NSLog("memlog: Auto-set target PID to \(pidInt) for \(model.name)")
                        return
                    }
                }
            }
        }
        NSLog("memlog: Target process '\(targetName)' not found or not running.")
    }
    
    // 禁用掉第三方输入法
//    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
//        return false
//    }

    func Audio() {
        
        let bundlePath = Bundle.main.bundlePath
        let path = "file://\(bundlePath)/LocalFiles/music.m4a"
        let url = URL(string: path)!
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
        } catch {
            audioPlayer = nil
        }
        
        audioPlayer?.prepareToPlay()
        audioPlayer?.volume = 0
        audioPlayer?.numberOfLoops = -1 // 循环播放
        
        do {
            // 后台播放音频
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        } catch {
            
        }
        
        // 接受远程控制
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    // 进入后台模式
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer?.play() // 播放
        } catch {
            
        }
    }
    
    // APP从后台进入到前台
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            audioPlayer?.pause() // 暂停
        } catch {
            
        }
    }
}
