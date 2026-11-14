// EncryptionManager.swift
import Foundation
import CryptoSwift

public class EncryptionManager {
    public static let shared = EncryptionManager()
    
    // Secret Key ขนาด 32 ไบต์พอดี ("YOUR_SUPER_SECURE_APP_SECRET_KEY")
    private let secretKeyBytes: [UInt8] = [
        0x59, 0x4F, 0x55, 0x52, 0x5F, 0x53, 0x55, 0x50, 
        0x45, 0x52, 0x5F, 0x53, 0x45, 0x43, 0x55, 0x52, 
        0x45, 0x5F, 0x41, 0x50, 0x50, 0x5F, 0x53, 0x45, 
        0x43, 0x52, 0x45, 0x54, 0x5F, 0x4B, 0x45, 0x59
    ] // แปลงมาจาก "YOUR_SUPER_SECURE_APP_SECRET_KEY" (32 chars)
    
    private let ivBytes: [UInt8] = [
        0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 
        0x39, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36
    ] // แปลงมาจาก "1234567890123456" (16 chars)
    
    private init() {}
    
    public func encrypt(parameters: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else { return nil }
            
            let aes = try AES(key: secretKeyBytes, blockMode: CBC(iv: ivBytes), padding: .pkcs7)
            let encryptedBytes = try aes.encrypt(Array(jsonString.utf8))
            
            return Data(encryptedBytes).base64EncodedString()
        } catch {
            print("Encryption Error: \(error.localizedDescription)")
            return nil
        }
    }
}
