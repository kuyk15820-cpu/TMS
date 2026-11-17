// APIConfiguration.swift
import Foundation

public struct APIConfiguration {
    // URL สำหรับระบบ License และ Auth เดิม
    public static let defaultBaseURL = "https://f1x3r.org/auth/api/connect.php"
    
    // 🟢 เพิ่ม Base URL หรือ URL แยกสำหรับระบบ UDID Enrollment
    public static let udidRequestURL = "https://f1x3r.org/udidX/request-udid.php"
    public static let udidCheckURL = "https://f1x3r.org/udidX/check-udid-status.php"
}
