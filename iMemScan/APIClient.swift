// APIClient.swift
import Foundation
import UIKit

@objcMembers
public class APIClient: NSObject {
    
    public static let sharedAPIClient = APIClient()
    
    private var packageToken: String = ""
    private var languageCode: String = "th"
    private var contactLink: String = ""
    private var isMaintenance: Bool = false
    private var isValidLicensed: Bool = false
    
    private var expiryDateCache: String = ""
    private var daysLeftCache: Int = 0
    private var onPaidExecuteBlock: (() -> Void)? = nil
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public SDK Methods
    
    public func setToken(_ token: String) {
        self.packageToken = token
        if !self.packageToken.isEmpty {
            self.startProcess()
        }
    }
    
    public func setLanguage(_ language: String) {
        self.languageCode = language
    }
    
    public func paid(execute: @escaping () -> Void) {
        self.onPaidExecuteBlock = execute
        
        if self.isValidLicensed {
            self.onPaidExecuteBlock?()
        } else {
            if !self.packageToken.isEmpty {
                self.startProcess()
            } else {
                self.showKeyInputPrompt()
            }
        }
    }
    
    public func showKeyInputPrompt() {
        LicenseAlertManager.shared.showKeyInputAlert(
            contactLink: self.contactLink,
            loginHandler: { key in
                // 🟢 สเตป 5 (เมื่อกดยืนยันคีย์): แสดง Check device... ตอนกำลังตรวจสอบคีย์
                DispatchQueue.main.async {
                    HUDHelper.show(title: "Check device…")
                }
                self.checkKey(key, isAuto: false)
            },
            contactHandler: {
                if !self.contactLink.isEmpty, let url = URL(string: self.contactLink) {
                    UIApplication.shared.open(url)
                }
                self.showKeyInputPrompt()
            }
        )
    }
    
    public func isLicenseValid() -> Bool {
        return self.isValidLicensed
    }
    
    public func enforceLicenseCheck() {
        if !self.isValidLicensed {
            self.showKeyInputPrompt()
        } else {
            if !self.packageToken.isEmpty {
                if let accessToken = UserDefaults.standard.string(forKey: "saved_access_token") {
                    self.checkWithAccessToken(accessToken)
                } else {
                    self.isValidLicensed = false
                    self.showKeyInputPrompt()
                }
            }
        }
    }
    
    // MARK: - Getter Methods for Key Info
    
    public func getKey() -> String? {
        return UserDefaults.standard.string(forKey: "saved_license_key")
    }
    
    public func getExpiryDate() -> String {
        return self.expiryDateCache
    }
    
    public func getUDID() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "00000"
    }
    
    public func getDeviceModel() -> String {
        return UIDevice.current.model
    }
    
    public func getLoginIP() -> String {
        return "Connected"
    }
    
    public func getPackageName() -> String {
        return "Default Package"
    }
    
    public func getDaysLeft() -> Int {
        return self.daysLeftCache
    }
    
    // MARK: - Process Flows (ลำดับการทำงาน Sequential Flow ตามจริง)
    
    private func startProcess() {
        guard !self.packageToken.isEmpty else { return }
        
        // 🟢 1. แสดง APIServer
        DispatchQueue.main.async {
            HUDHelper.show(title: "APIServer", subtitle: "Version: 1.0.0")
        }
        
        // 🟢 2. อัปเดตต่อกันแสดง Package initializing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            HUDHelper.update(title: "Package initializing")
        }
        
        APIService.shared.fetchInit(token: self.packageToken) { result in
            switch result {
            case .success(let json):
                if let forceExit = json["force_exit"] as? Bool, forceExit {
                    let msg = json["message"] as? String ?? "Token package không tồn tại."
                    self.forceExitApp(reason: msg)
                    return
                }
                
                if let status = json["status"] as? Bool, status {
                    self.contactLink = json["contact"] as? String ?? ""
                    self.isMaintenance = (json["maintenance"] as? Int) == 1
                    
                    DispatchQueue.main.async {
                        self.handleInitSuccess()
                    }
                } else {
                    let msg = json["message"] as? String ?? "Lỗi không xác định."
                    self.forceExitApp(reason: msg)
                }
            case .failure(let error):
                self.forceExitApp(reason: "Không thể kết nối đến server: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleInitSuccess() {
        if self.isMaintenance {
            LicenseAlertManager.shared.showMaintenanceAlert(contactLink: self.contactLink)
        } else {
            let ud = UserDefaults.standard
            if let accessToken = ud.string(forKey: "saved_access_token") {
                self.checkWithAccessToken(accessToken)
            } else if let savedKey = ud.string(forKey: "saved_license_key") {
                self.checkKey(savedKey, isAuto: true)
            } else {
                // 🟢 3. อัปเดตต่อกันแสดง Check device… ก่อนเด้งกล่องกรอกคีย์
                DispatchQueue.main.async {
                    HUDHelper.update(title: "Check device…")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    HUDHelper.hide()
                    self.triggerUDIDAndShowInput()
                }
            }
        }
    }
    
    // 🟢 4. แสดง FTNotificationIndicator UDID IDF + AlertController input
    private func triggerUDIDAndShowInput() {
        let currentUDID = self.getUDID()
        
        LicenseAlertManager.shared.showSuccessNotification(
            title: "UDID IDF",
            message: "UDID: \(currentUDID)\nAPI: 1.0.0"
        )
        
        self.showKeyInputPrompt()
    }
    
    private func checkWithAccessToken(_ accessToken: String) {
        DispatchQueue.main.async {
            HUDHelper.update(title: "Check device…")
            let currentUDID = self.getUDID()
            LicenseAlertManager.shared.showSuccessNotification(title: "UDID IDF", message: "UDID: \(currentUDID)\nAPI: 1.0.0")
        }
        
        APIService.shared.checkWithAccessToken(token: self.packageToken, accessToken: accessToken) { result in
            self.handleNetworkResult(result, key: "", isAuto: true, isAccessCheck: true)
        }
    }
    
    private func checkKey(_ key: String, isAuto: Bool) {
        let uuid = self.getUDID()
        APIService.shared.checkWithKey(token: self.packageToken, key: key, uuid: uuid) { result in
            self.handleNetworkResult(result, key: key, isAuto: isAuto, isAccessCheck: false)
        }
    }
    
    private func handleNetworkResult(_ result: Result<[String: Any], Error>, key: String, isAuto: Bool, isAccessCheck: Bool) {
        DispatchQueue.main.async {
            HUDHelper.hide()
        }
        
        switch result {
        case .success(let json):
            if let forceExit = json["force_exit"] as? Bool, forceExit {
                let msg = json["message"] as? String ?? "Token package lỗi."
                self.forceExitApp(reason: msg)
                return
            }
            
            if let forceReauth = json["force_reauth"] as? Bool, forceReauth {
                let msg = json["message"] as? String ?? "Session expired"
                self.handleInvalidKey(key: key, msg: msg, isAuto: isAccessCheck ? true : isAuto)
                return
            }
            
            if let contact = json["contact"] as? String {
                self.contactLink = contact
            }
            
            let status = json["status"] as? Bool ?? false
            if status {
                self.isValidLicensed = true
                
                if isAccessCheck {
                    DispatchQueue.main.async {
                        self.onPaidExecuteBlock?()
                    }
                    return
                }
                
                if let accessToken = json["access_token"] as? String {
                    UserDefaults.standard.set(accessToken, forKey: "saved_access_token")
                }
                
                let daysLeft = json["days_left"] as? Int ?? 0
                self.daysLeftCache = daysLeft
                let expiryStr = json["expiry"] as? String ?? ""
                self.expiryDateCache = expiryStr
                
                UserDefaults.standard.set(key, forKey: "saved_license_key")
                
                // 🟢 6. กรณีกรอกคีย์สำเร็จ แสดงการ์ด Hi iPhone พร้อมข้อมูลจริงและปุ่ม Tap to close
                let detailsText = """
                Expiry date: \(expiryStr)
                Device: iPhone X | System version: 16.0
                APIServer: 1.0.0
                """
                
                DispatchQueue.main.async {
                    HUDHelper.showSuccessCard(
                        title: "Hi iPhone",
                        details: detailsText,
                        buttonTitle: "Tap to close"
                    ) {
                        self.onPaidExecuteBlock?()
                    }
                }
            } else {
                let msg = json["message"] as? String ?? "Invalid Key"
                self.handleInvalidKey(key: key, msg: msg, isAuto: isAuto)
            }
            
        case .failure(let error):
            DispatchQueue.main.async {
                HUDHelper.showMessage(title: "Lỗi kết nối", subtitle: error.localizedDescription, autoHideDelay: 2.0)
            }
        }
    }
    
    private func handleInvalidKey(key: String, msg: String, isAuto: Bool) {
        self.isValidLicensed = false
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "saved_license_key")
        ud.removeObject(forKey: "saved_access_token")
        
        // 🟢 5. กรณีกรอกคีย์ผิด แสดง HUD แบบไม่มี Spinner (Please check your key / Package will close after 1)
        DispatchQueue.main.async {
            HUDHelper.showMessage(
                title: "Please check your key",
                subtitle: "Package will close after 1",
                autoHideDelay: 2.0
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showKeyInputPrompt()
        }
    }
    
    private func forceExitApp(reason: String) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let rootVC = window.rootViewController else {
                exit(0)
            }
            let alert = UIAlertController(title: "Lỗi Hệ Thống", message: reason, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Thoát", style: .destructive) { _ in
                exit(0)
            })
            rootVC.present(alert, animated: true)
        }
    }
}
