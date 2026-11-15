import SwiftUI
import UIKit
import MBProgressHUD

struct HUDHelper {
    private static var currentHUD: MBProgressHUD?

    @MainActor
    static func show(message: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }
        
        // เคลียร์ตัวเก่าทันทีหากเปิดค้างไว้
        if let existingHUD = currentHUD {
            existingHUD.hide(animated: false)
            currentHUD = nil
        }

        let hud = MBProgressHUD.showAdded(to: window, animated: true)
        hud.mode = .indeterminate
        
        // 🟢 กำหนด Background Style แบบถอดมาจาก Objective-C
        hud.backgroundView.style = MBProgressHUDBackgroundStyle.solidColor
        hud.backgroundView.color = UIColor(white: 0.0, alpha: 0.4)
        
        // 🟢 กำหนด Bezel และ Content Style ให้ตรงตาม Objective-C
        hud.bezelView.blurEffectStyle = .dark
        hud.contentColor = .white
        hud.label.text = message
        hud.label.textColor = .lightGray
        
        currentHUD = hud
    }

    @MainActor
    static func update(message: String) {
        if let hud = currentHUD {
            hud.label.text = message
        } else {
            show(message: message)
        }
    }

    @MainActor
    static func hide() {
        guard let hud = currentHUD else { return }
        
        // ซ่อนทันทีตามเวลาจริงของการโหลดข้อมูล
        hud.hide(animated: true)
        currentHUD = nil
    }
}
