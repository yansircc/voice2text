import Foundation

protocol WhisperServiceDelegate: AnyObject {
    func whisperService(_ service: WhisperService, didReceivePartialTranscription text: String)
    func whisperService(_ service: WhisperService, didCompleteTranscription text: String)
    func whisperService(_ service: WhisperService, didFailWithError error: Error)
}

class WhisperService: NSObject {
    private let configuration: WhisperConfiguration
    private var session: URLSession!
    weak var delegate: WhisperServiceDelegate?
    private var streamBuffer = ""
    private var dataBuffer = Data()
    private var fullTranscription = ""
    
    override init() {
        self.configuration = WhisperConfiguration()
        super.init()
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    init(configuration: WhisperConfiguration) {
        self.configuration = configuration
        super.init()
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // Original non-streaming method (kept for compatibility)
    func transcribe(audioData: Data, filename: String = "audio.wav") async throws -> String {
        try configuration.validate()
        
        guard let url = URL(string: configuration.transcriptionEndpoint) else {
            throw WhisperError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = createMultipartBody(
            audioData: audioData,
            filename: filename,
            boundary: boundary
        )
        
        request.httpBody = httpBody
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhisperError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw WhisperError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        // Parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String {
            return text
        }
        
        throw WhisperError.invalidResponse
    }
    
    private func createMultipartBody(audioData: Data, filename: String, boundary: String) -> Data {
        var body = Data()
        
        // File data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(configuration.modelId)\r\n".data(using: .utf8)!)
        
        // Language
        if let language = configuration.language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // Prompt
        if let prompt = configuration.prompt, !prompt.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(prompt)\r\n".data(using: .utf8)!)
        }
        
        // Temperature
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(configuration.temperature)\r\n".data(using: .utf8)!)
        
        // Response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    // Streaming transcription method
    func transcribeStreaming(audioData: Data, filename: String = "audio.wav") {
        // Reset buffers
        streamBuffer = ""
        dataBuffer = Data()
        fullTranscription = ""
        
        do {
            try configuration.validate()
            
            guard let url = URL(string: configuration.transcriptionEndpoint) else {
                throw WhisperError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
            
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            let httpBody = createStreamingMultipartBody(
                audioData: audioData,
                filename: filename,
                boundary: boundary
            )
            
            request.httpBody = httpBody
            
            // Use dataTask to enable streaming via delegate
            let task = session.dataTask(with: request)
            task.resume()
            
        } catch {
            DispatchQueue.main.async {
                self.delegate?.whisperService(self, didFailWithError: error)
            }
        }
    }
    
    private func createStreamingMultipartBody(audioData: Data, filename: String, boundary: String) -> Data {
        var body = Data()
        
        // File data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(configuration.modelId)\r\n".data(using: .utf8)!)
        
        // Language
        if let language = configuration.language {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }
        
        // Prompt
        if let prompt = configuration.prompt, !prompt.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(prompt)\r\n".data(using: .utf8)!)
        }
        
        // Temperature
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(configuration.temperature)\r\n".data(using: .utf8)!)
        
        // Response format - use json for structured response
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("json\r\n".data(using: .utf8)!)
        
        // Note: This API doesn't support stream parameter
        // If your API supports streaming in the future, uncomment below:
        // body.append("--\(boundary)\r\n".data(using: .utf8)!)
        // body.append("Content-Disposition: form-data; name=\"stream\"\r\n\r\n".data(using: .utf8)!)
        // body.append("true\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}

enum WhisperError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case audioConversionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .audioConversionFailed:
            return "Failed to convert audio to required format"
        }
    }
}

// MARK: - URLSessionDataDelegate for streaming
extension WhisperService: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // Check if response is valid
        if let httpResponse = response as? HTTPURLResponse {
            print("DEBUG: HTTP Response Status Code: \(httpResponse.statusCode)")
            print("DEBUG: HTTP Response Headers: \(httpResponse.allHeaderFields)")
            
            if httpResponse.statusCode == 200 {
                completionHandler(.allow)
            } else {
                // Allow receiving error message body
                completionHandler(.allow)
            }
        } else {
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Append new data to buffer
        dataBuffer.append(data)
        
        // Debug: Log raw data (commented out for cleaner output)
        // if let dataString = String(data: data, encoding: .utf8) {
        //     print("DEBUG: Received data chunk: \(dataString.prefix(200))...")
        // }
        
        // Try to parse SSE events from the buffer
        if let dataString = String(data: dataBuffer, encoding: .utf8) {
            // print("DEBUG: Buffer contains: \(dataString.prefix(500))...")
            
            // Check content type from response headers to determine format
            if let response = dataTask.response as? HTTPURLResponse,
               let contentType = response.allHeaderFields["Content-Type"] as? String {
                print("DEBUG: Content-Type: \(contentType)")
                
                if contentType.contains("text/event-stream") || dataString.hasPrefix("data: ") {
                    // SSE format: "data: {json}\n\n"
                    print("DEBUG: Detected SSE format")
                    let lines = dataString.components(separatedBy: "\n")
                    var processedLength = 0
                    
                    for line in lines {
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            print("DEBUG: Parsing SSE line: \(jsonString)")
                            
                            // Check for [DONE] marker
                            if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                                print("DEBUG: Stream ended with [DONE]")
                                DispatchQueue.main.async {
                                    self.delegate?.whisperService(self, didCompleteTranscription: self.fullTranscription)
                                }
                                processedLength += (line + "\n").count
                                continue
                            }
                            
                            // Try to parse JSON
                            if let jsonData = jsonString.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                
                                // Check for different response formats
                                if let text = json["text"] as? String {
                                    // Each chunk might contain partial text
                                    fullTranscription += text
                                    print("DEBUG: Found text chunk in SSE: \(text)")
                                    DispatchQueue.main.async {
                                        self.delegate?.whisperService(self, didReceivePartialTranscription: text)
                                    }
                                } else if let choices = json["choices"] as? [[String: Any]],
                                          let delta = choices.first?["delta"] as? [String: Any],
                                          let content = delta["content"] as? String {
                                    // OpenAI streaming format
                                    fullTranscription += content
                                    print("DEBUG: Found delta content: \(content)")
                                    DispatchQueue.main.async {
                                        self.delegate?.whisperService(self, didReceivePartialTranscription: content)
                                    }
                                }
                            }
                            
                            // Mark this line as processed
                            processedLength += (line + "\n").count
                        } else if line.isEmpty {
                            // Empty line separates SSE events
                            processedLength += 1
                        }
                    }
                    
                    // Remove processed data from buffer
                    if processedLength > 0 && processedLength <= dataBuffer.count {
                        dataBuffer = dataBuffer.subdata(in: processedLength..<dataBuffer.count)
                    }
                }
                // If not SSE format, it's regular JSON (will be handled in didCompleteWithError)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("DEBUG: Request completed. Error: \(error?.localizedDescription ?? "none")")
        print("DEBUG: Full transcription so far: \(fullTranscription)")
        print("DEBUG: Data buffer size: \(dataBuffer.count)")
        
        // Check if we have an HTTP error response
        if let httpResponse = task.response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("DEBUG: HTTP Error Status: \(httpResponse.statusCode)")
            if let errorString = String(data: dataBuffer, encoding: .utf8) {
                print("DEBUG: Error response body: \(errorString)")
                let error = WhisperError.apiError(statusCode: httpResponse.statusCode, message: errorString)
                DispatchQueue.main.async {
                    self.delegate?.whisperService(self, didFailWithError: error)
                }
                // Clear buffers and return
                dataBuffer = Data()
                streamBuffer = ""
                fullTranscription = ""
                return
            }
        }
        
        if let error = error {
            DispatchQueue.main.async {
                self.delegate?.whisperService(self, didFailWithError: error)
            }
        } else if !fullTranscription.isEmpty {
            DispatchQueue.main.async {
                self.delegate?.whisperService(self, didCompleteTranscription: self.fullTranscription)
            }
        } else if !dataBuffer.isEmpty {
            // Try to parse any remaining data as non-streaming response
            print("DEBUG: Trying to parse non-streaming response")
            if let dataString = String(data: dataBuffer, encoding: .utf8) {
                print("DEBUG: Non-streaming response: \(dataString)")
            }
            
            if let json = try? JSONSerialization.jsonObject(with: dataBuffer) as? [String: Any] {
                print("DEBUG: Parsed JSON: \(json)")
                if let text = json["text"] as? String {
                    print("DEBUG: Found text in non-streaming response: \(text)")
                    DispatchQueue.main.async {
                        self.delegate?.whisperService(self, didCompleteTranscription: text)
                    }
                }
            } else {
                print("DEBUG: Failed to parse JSON from buffer")
            }
        } else {
            print("DEBUG: No transcription received")
        }
        
        // Clear buffers
        dataBuffer = Data()
        streamBuffer = ""
        fullTranscription = ""
    }
}