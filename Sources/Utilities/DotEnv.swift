import Foundation

class DotEnv {
    static func load(from filename: String = ".env") {
        let currentPath = FileManager.default.currentDirectoryPath
        let envPath = "\(currentPath)/\(filename)"
        
        guard FileManager.default.fileExists(atPath: envPath) else {
            print("Note: \(filename) file not found at \(envPath)")
            print("Using environment variables or command-line arguments instead.")
            return
        }
        
        do {
            let contents = try String(contentsOfFile: envPath, encoding: .utf8)
            let lines = contents.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                // Skip empty lines and comments
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                // Parse key=value pairs
                let parts = trimmedLine.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    var value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    
                    // Remove quotes if present
                    if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                       (value.hasPrefix("'") && value.hasSuffix("'")) {
                        value = String(value.dropFirst().dropLast())
                    }
                    
                    // Only set if not already set (command-line args take precedence)
                    if ProcessInfo.processInfo.environment[key] == nil {
                        setenv(key, value, 0)
                    }
                }
            }
            
            print("Loaded configuration from \(filename)")
        } catch {
            print("Error loading \(filename): \(error)")
        }
    }
}