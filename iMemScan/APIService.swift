// APIService.swift
import Foundation

public class APIService {
    public static let shared = APIService()
    
    private init() {}
    
    // ฟังก์ชันกลางสำหรับยิง Request แบบ POST พร้อมเข้ารหัส Payload ผ่าน EncryptionManager
    private func postEncryptedRequest(parameters: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: APIConfiguration.defaultBaseURL) else {
            let error = NSError(domain: "APIServiceError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        
        // 1. เข้ารหัสพารามิเตอร์ทั้งหมดด้วย EncryptionManager
        guard let encryptedPayload = EncryptionManager.shared.encrypt(parameters: parameters) else {
            let error = NSError(domain: "APIServiceError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Encryption failed"])
            completion(.failure(error))
            return
        }
        
        // 2. สร้าง Body ในรูปแบบ JSON: {"payload": "..."}
        let bodyDictionary: [String: String] = ["payload": encryptedPayload]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: bodyDictionary, options: []) else {
            let error = NSError(domain: "APIServiceError", code: -5, userInfo: [NSLocalizedDescriptionKey: "JSON Serialization failed"])
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "APIServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completion(.failure(error))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(.success(json))
                } else {
                    let error = NSError(domain: "APIServiceError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // ยิง Init เพื่อเช็กสถานะแพ็กเกจและ Maintenance (ส่งแบบ POST + Encrypted Payload)
    public func fetchInit(token: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let params: [String: Any] = [
            "action": "init",
            "token": token
        ]
        postEncryptedRequest(parameters: params, completion: completion)
    }
    
    // ยิง Check (กรณีใช้ Access Token ตรวจสอบเซสชันอัตโนมัติ)
    public func checkWithAccessToken(token: String, accessToken: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let params: [String: Any] = [
            "action": "check",
            "token": token,
            "access_token": accessToken
        ]
        postEncryptedRequest(parameters: params, completion: completion)
    }
    
    // ยิง Check (กรณีผู้ใช้กรอก Key ใหม่พร้อม UDID)
    public func checkWithKey(token: String, key: String, uuid: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let params: [String: Any] = [
            "action": "check",
            "token": token,
            "key": key,
            "uuid": uuid
        ]
        postEncryptedRequest(parameters: params, completion: completion)
    }
}
