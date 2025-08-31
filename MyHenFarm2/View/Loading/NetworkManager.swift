//
//  NetworkManager.swift
//  TestLoadingView
//
//  Created by Роман Главацкий on 16.08.2025.
//
import Foundation

class NetworkManager {
    private let configuration: NetworkConfiguration
    
    init(configuration: NetworkConfiguration = .default) {
        self.configuration = configuration
    }
    
    convenience init(baseURL: String) {
        var config = AppParameters.networkConfiguration
        config.baseURL = baseURL
        self.init(configuration: config)
    }
    
    func sendConversionData(appsFlyerData: [String: Any?], additionalData: [String: Any], completion: @escaping (Result<Data, NSError>) -> Void) {
        guard let url = URL(string: configuration.baseURL) else {
            let nsError = NSError(domain: "NetworkManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: NetworkError.invalidURL.errorDescription ?? "Invalid URL"])
            completion(.failure(nsError))
            return
        }
        let requestBody = prepareRequestBody(appsFlyerData: appsFlyerData, additionalData: additionalData)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = configuration.timeoutInterval
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            request.httpBody = jsonData
        } catch {
            let nsError = NSError(domain: "NetworkManager", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Encoding error: \(error.localizedDescription)"])
            completion(.failure(nsError))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                let nsError = NSError(domain: "NetworkManager", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Network error: \(error.localizedDescription)"])
                completion(.failure(nsError))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200..<300:
                    break
                default:
                    let nsError = NSError(domain: "NetworkManager", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: NetworkError.serverError(statusCode: httpResponse.statusCode).errorDescription ?? "Server error"])
                    completion(.failure(nsError))
                    return
                }
            }

            guard let data = data else {
                let nsError = NSError(domain: "NetworkManager", code: 1004, userInfo: [NSLocalizedDescriptionKey: NetworkError.noData.errorDescription ?? "No data"])
                completion(.failure(nsError))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }
    
    // MARK: - Private Methods
    
    private func prepareRequestBody(appsFlyerData: [String: Any?], additionalData: [String: Any]) -> [String: Any] {
        var requestBody: [String: Any] = [:]
        
        for (key, value) in appsFlyerData {
            if value != nil {
                requestBody[key] = value!
            }
        }
        
        additionalData.forEach { requestBody[$0.key] = $0.value }
        
        requestBody["timestamp"] = Date().timeIntervalSince1970
        
        return requestBody
    }
    
    enum NetworkError: Error, LocalizedError {
        case invalidURL
        case noData
        case serverError(statusCode: Int)
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Bad URL"
            case .noData:
                return "no data"
            case .serverError(let statusCode):
                return "Error server (\(statusCode))"
            }
        }
    }
}
