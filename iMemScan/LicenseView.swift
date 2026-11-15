// LicenseAlertManager.swift
import UIKit
import SwiftUI

// 🟢 SwiftUI View สำหรับหน้าต่าง Maintenance (ปิดปรับปรุง)
struct MaintenanceView: View {
    var contactLink: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Bảo Trì")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Hệ thống đang bảo trì.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if !contactLink.isEmpty, let url = URL(string: contactLink) {
                    Button("Liên hệ") {
                        UIApplication.shared.open(url)
                        exit(0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                } else {
                    Button("Thoát") {
                        exit(0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
    }
}

// 🟢 Manager สำหรับจัดการการแสดงผล FTNotificationIndicator และ UIAlertController
public class LicenseAlertManager {
    public static let shared = LicenseAlertManager()
    
    private init() {}
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topVC = window.rootViewController else {
            return nil
        }
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
    
    // แสดง Notification สำเร็จด้วย FTNotificationIndicator (ใช้แสดง UDID IDF)
    public func showSuccessNotification(title: String, message: String) {
        DispatchQueue.main.async {
            let icon = UIImage(systemName: "checkmark.circle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            FTNotificationIndicator.setNotificationIndicatorStyle(.dark)
            FTNotificationIndicator.showNotification(with: icon, title: title, message: message)
        }
    }
    
    // แสดง Notification ข้อผิดพลาดด้วย FTNotificationIndicator
    public func showErrorNotification(title: String, message: String) {
        DispatchQueue.main.async {
            let icon = UIImage(systemName: "exclamationmark.triangle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            FTNotificationIndicator.setNotificationIndicatorStyle(.dark)
            FTNotificationIndicator.showNotification(with: icon, title: title, message: message)
        }
    }
    
    // 🟢 แสดงหน้าต่างกรอก Key ด้วย UIKit UIAlertController (พร้อมช่อง Input TextField)
    public func showKeyInputAlert(contactLink: String, loginHandler: @escaping (String) -> Void, contactHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard let rootVC = self.getTopViewController() else { return }
            
            let alert = UIAlertController(
                title: "Nhập Key",
                message: "Vui lòng nhập key để kích hoạt.",
                preferredStyle: .alert
            )
            
            // เพิ่ม TextField สำหรับกรอก License Key
            alert.addTextField { textField in
                textField.placeholder = "License Key"
                textField.autocapitalizationType = .none
                textField.isSecureTextEntry = false
                textField.clearButtonMode = .whileEditing
            }
            
            // ปุ่ม Login
            let loginAction = UIAlertAction(title: "Login", style: .default) { _ in
                if let key = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty {
                    loginHandler(key)
                } else {
                    // หากไม่ได้กรอกแล้วกด Login ให้เรียกซ้ำ
                    self.showKeyInputAlert(contactLink: contactLink, loginHandler: loginHandler, contactHandler: contactHandler)
                }
            }
            alert.addAction(loginAction)
            
            // ปุ่ม Contact (แสดงเฉพาะเมื่อมีลิงก์ติดต่อ)
            if !contactLink.isEmpty {
                let contactAction = UIAlertAction(title: "Contact", style: .default) { _ in
                    contactHandler()
                }
                alert.addAction(contactAction)
            }
            
            // ปุ่ม Cancel / ออกจากแอป
            let cancelAction = UIAlertAction(title: "Thoát", style: .destructive) { _ in
                exit(0)
            }
            alert.addAction(cancelAction)
            
            rootVC.present(alert, animated: true)
        }
    }
    
    // แสดงหน้าต่าง SwiftUI ปิดปรับปรุงระบบ (Maintenance)
    public func showMaintenanceAlert(contactLink: String) {
        DispatchQueue.main.async {
            guard let rootVC = self.getTopViewController() else { return }
            let view = MaintenanceView(contactLink: contactLink)
            let hostingController = UIHostingController(rootView: view)
            let hcView = hostingController.view
            hcView?.backgroundColor = .clear
            hcView?.frame = rootVC.view.bounds
            rootVC.view.addSubview(hcView!)
        }
    }
}
