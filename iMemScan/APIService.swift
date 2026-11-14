// APIService.swift
import Foundation

public class APIService {
    public static let shared = APIService()
    
    private init() {}
    
    // ยิง Init เพื่อเช็กสถานะแพ็กเกจและ Maintenance
    public func fetchInit(token: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let urlString = "\(APIConfiguration.defaultBaseURL)?action=init&token=\(token)"
        requestJSON(urlString: urlString, completion: completion)
    }
    
    // ยิง Check (กรณีใช้ Access Token ตรวจสอบเซสชันอัตโนมัติ)
    public func checkWithAccessToken(token: String, accessToken: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let urlString = "\(APIConfiguration.defaultBaseURL)?action=check&token=\(token)&access_token=\(accessToken)"
        requestJSON(urlString: urlString, completion: completion)
    }
    
    // ยิง Check (กรณีผู้ใช้กรอก Key ใหม่พร้อม UDID)
    public func checkWithKey(token: String, key: String, uuid: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let urlString = "\(APIConfiguration.defaultBaseURL)?action=check&token=\(token)&key=\(key)&uuid=\(uuid)"
        requestJSON(urlString: urlString, completion: completion)
    }
    
    private func requestJSON(urlString: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            let error = NSError(domain: "APIServiceError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
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
}
