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
        overrideUserInterfacrStyle()
        
        // 🟢 สั่งให้ค้นหาและเซ็ต PID อัตโนมัติทันทีที่แอปเปิด (โดยเช็คจากแอปที่กำลังรันอยู่)
        autoSetTargetProcess()
        
        return true
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
