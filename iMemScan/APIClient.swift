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
    
    // ตัวแปรเก็บค่า UDID จริง 40 หลักที่ได้จาก Safari Profile
    private var cachedRealUDID: String {
        get { UserDefaults.standard.string(forKey: "saved_real_udid") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "saved_real_udid") }
    }
    
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
    
    // ตรวจสอบว่ามี UDID จริงหรือยัง ถ้ายังให้เริ่มกระบวนการขอโปรไฟล์ UDID ก่อน
    public func showKeyInputPrompt() {
        if self.cachedRealUDID.isEmpty {
            self.startUDIDEnrollmentFlow()
        } else {
            self.presentKeyInputAlert()
        }
    }
    
    private func presentKeyInputAlert() {
        LicenseAlertManager.shared.showKeyInputAlert(
            contactLink: self.contactLink,
            loginHandler: { key in
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
        let realUDID = self.cachedRealUDID
        if !realUDID.isEmpty {
            return realUDID
        }
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
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
    
    // MARK: - UDID Enrollment Flow (เปิด Safari แล้ว Exit แอปทันที)
    
    private func startUDIDEnrollmentFlow() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let rootVC = window.rootViewController else { return }
            
            let alert = UIAlertController(title: "ลงทะเบียนอุปกรณ์", message: "ระบบจำเป็นต้องติดตั้งโปรไฟล์เพื่อความปลอดภัยและผูก UDID ของเครื่องคุณ หลังจากติดตั้งเสร็จแล้วให้เปิดแอปใหม่อีกครั้ง", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ดำเนินการต่อ", style: .default) { _ in
                self.requestAndOpenSafariProfile()
            })
            alert.addAction(UIAlertAction(title: "ยกเลิก", style: .cancel))
            rootVC.present(alert, animated: true)
        }
    }
    
    private func requestAndOpenSafariProfile() {
        // ส่ง Request ขอ Session Token จากเซิร์ฟเวอร์
        APIService.shared.requestUDIDSession(projectId: 1) { result in
            switch result {
            case .success(let json):
                if let status = json["status"] as? Bool, status,
                   let profileURLStr = json["profile_url"] as? String,
                   let sessionToken = json["session_token"] as? String,
                   let url = URL(string: profileURLStr) {
                    
                    // บันทึก sessionToken ไว้ตรวจสอบเมื่อผู้ใช้เปิดแอปกลับมาใหม่
                    UserDefaults.standard.set(sessionToken, forKey: "pending_udid_session_token")
                    
                    DispatchQueue.main.async {
                        // เปิด Safari ไปที่หน้าติดตั้งโปรไฟล์
                        UIApplication.shared.open(url, options: [:]) { success in
                            if success {
                                // 🟢 ปิดแอปทันทีเพื่อประหยัดทรัพยากรและรอให้ผู้ใช้ติดตั้งเสร็จค่อยเปิดใหม่
                                exit(0)
                            }
                        }
                    }
                }
            case .failure(let error):
                print("Failed to request UDID session: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Process Flows
    
    private func startProcess() {
        guard !self.packageToken.isEmpty else { return }
        
        // 🟢 ตรวจสอบว่ามี Session ค้างอยู่จากการกลับมาจากติดตั้งโปรไฟล์ Safari หรือไม่
        if let pendingToken = UserDefaults.standard.string(forKey: "pending_udid_session_token") {
            UserDefaults.standard.removeObject(forKey: "pending_udid_session_token")
            
            // เช็กสถานะกับเซิร์ฟเวอร์ทันทีว่าได้ UDID หรือยัง
            APIService.shared.checkUDIDStatus(sessionToken: pendingToken) { result in
                switch result {
                case .success(let json):
                    if let status = json["status"] as? Bool, status,
                       let udid = json["udid"] as? String, !udid.isEmpty {
                        // บันทึก UDID จริงลงเครื่องสำเร็จ
                        self.cachedRealUDID = udid
                    }
                case .failure:
                    break
                }
                // ดำเนินกระบวนการตรวจสอบสิทธิ์ต่อตามปกติ
                self.proceedAfterUDIDCheck()
            }
            return
        }
        
        proceedAfterUDIDCheck()
    }
    
    private func proceedAfterUDIDCheck() {
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
                self.showKeyInputPrompt()
            }
        }
    }
    
    private func checkWithAccessToken(_ accessToken: String) {
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
                self.expiryDateCache = json["expiry"] as? String ?? ""
                
                UserDefaults.standard.set(key, forKey: "saved_license_key")
                
                let expiryStr = json["expiry"] as? String ?? ""
                let info = "Hạn dùng: \(expiryStr) (\(daysLeft) ngày)"
                
                LicenseAlertManager.shared.showSuccessNotification(title: "Thành công", message: info)
                
                DispatchQueue.main.async {
                    self.onPaidExecuteBlock?()
                }
            } else {
                let msg = json["message"] as? String ?? "Invalid Key"
                self.handleInvalidKey(key: key, msg: msg, isAuto: isAuto)
            }
            
        case .failure(let error):
            LicenseAlertManager.shared.showErrorNotification(title: "Lỗi kết nối", message: error.localizedDescription)
        }
    }
    
    private func handleInvalidKey(key: String, msg: String, isAuto: Bool) {
        self.isValidLicensed = false
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "saved_license_key")
        ud.removeObject(forKey: "saved_access_token")
        
        // 🟢 เคลียร์ UDID จริงในเครื่องทิ้งด้วย เมื่อโดนรีเซ็ตจาก Server หรือ Key มีปัญหา
        ud.removeObject(forKey: "saved_real_udid")
        
        if isAuto {
            self.showKeyInputPrompt()
        } else {
            LicenseAlertManager.shared.showErrorNotification(title: "Lỗi Key", message: msg)
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
