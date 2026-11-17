// APIConfiguration.swift
import Foundation

public struct APIConfiguration {
    // URL สำหรับระบบ License และ Auth เดิม
    public static let defaultBaseURL = "https://f1x3r.org/auth/api/connect.php"
    
    // 🟢 URL สำหรับระบบ UDID Enrollment แบบแยกไฟล์
    public static let requestUDIDURL = "https://f1x3r.org/udidX/request-udid.php"
    public static let checkUDIDStatusURL = "https://f1x3r.org/udidX/check-udid-status.php"
}
