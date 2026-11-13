// LicenseAlertManager.swift
import UIKit
import SwiftUI

// 🟢 SwiftUI View สำหรับหน้าต่างกรอก Key
struct KeyInputView: View {
    @Binding var isPresented: Bool
    var contactLink: String
    var onLogin: (String) -> Void
    var onContact: () -> Void
    
    @State private var keyInput: String = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Nhập Key")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Vui lòng nhập key để kích hoạt.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                TextField("License Key", text: $keyInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    if !contactLink.isEmpty {
                        Button("Contact") {
                            onContact()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    Button("Login") {
                        if !keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onLogin(keyInput)
                            isPresented = false
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
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

// 🟢 Manager สำหรับเรียกแสดงผลผ่าน FTNotificationIndicator และ SwiftUI HostingController
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
    
    // แสดง Notification สำเร็จด้วย FTNotificationIndicator
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
    
    // แสดงหน้าต่าง SwiftUI กรอก Key
    public func showKeyInputAlert(contactLink: String, loginHandler: @escaping (String) -> Void, contactHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard let rootVC = self.getTopViewController() else { return }
            
            var hostingController: UIHostingController<KeyInputView>?
            let view = KeyInputView(isPresented: Binding(
                get: { true },
                set: { if !$0 { hostingController?.view.removeFromSuperview() } }
            ), contactLink: contactLink, onLogin: { key in
                loginHandler(key)
                hostingController?.view.removeFromSuperview()
            }, onContact: {
                contactHandler()
            })
            
            hostingController = UIHostingController(rootView: view)
            guard let hcView = hostingController?.view else { return }
            hcView.backgroundColor = .clear
            hcView.frame = rootVC.view.bounds
            rootVC.view.addSubview(hcView)
        }
    }
    
    // แสดงหน้าต่าง SwiftUI ปิดปรับปรุง
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
