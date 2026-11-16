import SwiftUI
import UIKit
import MBProgressHUD

struct HUDHelper {
    private static var currentHUD: MBProgressHUD?

    // 1, 2, 3: แสดง HUD แบบมี Spinner (Indeterminate mode)
    @MainActor
    static func show(title: String, subtitle: String = "") {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        if let existingHUD = currentHUD {
            existingHUD.hide(animated: false)
            currentHUD = nil
        }

        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = .indeterminate
        
        hud.backgroundView.style = .solidColor
        hud.backgroundView.color = UIColor(white: 0.0, alpha: 0.4)
        hud.bezelView.blurEffectStyle = .dark
        hud.contentColor = .white
        
        hud.label.text = title
        if !subtitle.isEmpty {
            hud.detailsLabel.text = subtitle
            hud.detailsLabel.numberOfLines = 0
        }
        
        currentHUD = hud
    }

    @MainActor
    static func update(title: String, subtitle: String? = nil) {
        if let hud = currentHUD {
            hud.label.text = title
            if let sub = subtitle {
                hud.detailsLabel.text = sub
            }
        } else {
            show(title: title, subtitle: subtitle ?? "")
        }
    }

    // 5: กรณีเกิดข้อผิดพลาด แสดงแบบ Text Only (ไม่มี Spinner) ตามตัวอย่าง Demo
    @MainActor
    static func showMessage(title: String, subtitle: String, autoHideDelay: TimeInterval = 2.0) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        if let existingHUD = currentHUD {
            existingHUD.hide(animated: false)
            currentHUD = nil
        }

        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = .text // โหมดข้อความอย่างเดียว
        
        hud.backgroundView.style = .solidColor
        hud.backgroundView.color = UIColor(white: 0.0, alpha: 0.4)
        hud.bezelView.blurEffectStyle = .dark
        hud.contentColor = .white
        
        hud.label.text = title
        hud.detailsLabel.text = subtitle
        hud.detailsLabel.numberOfLines = 0
        
        currentHUD = hud
        
        if autoHideDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + autoHideDelay) {
                if currentHUD == hud {
                    hud.hide(animated: true)
                    currentHUD = nil
                }
            }
        }
    }

    // 6: กรณีกรอกคีย์สำเร็จ แสดง Custom View + Details + Button ตามตัวอย่างต้นฉบับ (ไม่ฟิกซ์ขนาด Frame ของ Icon)
    @MainActor
    static func showSuccessCard(title: String, details: String, buttonTitle: String, onClose: @escaping () -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        if let existingHUD = currentHUD {
            existingHUD.hide(animated: false)
            currentHUD = nil
        }

        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = .customView
        
        // ใช้แนวทางเดียวกับ customViewExample ใน Demo (ไม่กำหนด frame ขนาดบังคับ ปล่อยให้ระบบจัดการตามธรรมชาติ)
        let image = UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)
        hud.customView = UIImageView(image: image)
        hud.isSquare = true
        
        hud.backgroundView.style = .solidColor
        hud.backgroundView.color = UIColor(white: 0.0, alpha: 0.5)
        hud.bezelView.blurEffectStyle = .dark
        hud.contentColor = .white
        
        hud.label.text = title
        hud.detailsLabel.text = details
        hud.detailsLabel.numberOfLines = 0
        
        // ปุ่มกดปิด (มีมาให้ในตัวไลบรารี MBProgressHUD)
        hud.button.setTitle(buttonTitle, for: .normal)
        hud.button.addAction(UIAction { _ in
            hud.hide(animated: true)
            currentHUD = nil
            onClose()
        }, for: .touchUpInside)
        
        currentHUD = hud
    }

    @MainActor
    static func hide() {
        guard let hud = currentHUD else { return }
        hud.hide(animated: true)
        currentHUD = nil
    }
}
