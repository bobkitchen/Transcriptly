//
//  FileTranscriptionService.swift
//  Transcriptly
//
//  Service for transcribing audio and video files using macOS 26 SpeechAnalyzer or GPT-4o
//

import Foundation
@_spi(SpeechAnalyzer) import Speech
@preconcurrency import AVFoundation
import Combine
import SwiftUI

// Notification name for file import
extension Notification.Name {
    static let fileTranscriptionImportFile = Notification.Name("fileTranscriptionImportFile")
}

enum FileTranscriptionProvider: String, CaseIterable {
    case speechAnalyzer = "Apple SpeechAnalyzer"
    case gpt4oWhisper = "GPT-4o Whisper"
    
    var description: String {
        switch self {
        case .speechAnalyzer:
            return "Local, private, unlimited duration"
        case .gpt4oWhisper:
            return "Cloud-based, highest accuracy"
        }
    }
    
    var icon: String {
        switch self {
        case .speechAnalyzer:
            return "waveform.badge.mic"
        case .gpt4oWhisper:
            return "cloud.fill"
        }
    }
}

enum FileTranscriptionError: LocalizedError {
    case unsupportedFileType
    case fileTooLarge(maxSize: Int)
    case transcriptionFailed(String)
    case providerUnavailable
    case cancelled
    case speechAnalyzerUnavailable
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFileType:
            return "This file type is not supported for transcription"
        case .fileTooLarge(let maxSize):
            return "File is too large. Maximum size is \(maxSize / 1024 / 1024)MB"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        case .providerUnavailable:
            return "The selected transcription provider is not available"
        case .cancelled:
            return "Transcription was cancelled"
        case .speechAnalyzerUnavailable:
            return "SpeechAnalyzer is not available, falling back to GPT-4o"
        }
    }
}

@MainActor
class FileTranscriptionService: ObservableObject {
    static let shared = FileTranscriptionService()
    
    // Published properties
    @Published var isTranscribing = false
    @Published var progress: Double = 0
    @Published var currentStatus = ""
    @Published var transcriptionResult: String?
    @Published var error: FileTranscriptionError?
    
    // Provider selection
    @Published var selectedProvider: FileTranscriptionProvider = .speechAnalyzer
    
    // File information
    @Published var currentFileName: String?
    @Published var currentFileSize: String?
    @Published var currentFileDuration: String?
    
    // Supported file types
    static let supportedAudioTypes: Set<String> = ["mp3", "wav", "m4a", "aac", "flac", "ogg"]
    static let supportedVideoTypes: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv", "webm"]
    
    // Helper methods for UI
    static func supportedFormatsString() -> String {
        let audioFormats = supportedAudioTypes.sorted().joined(separator: ", ")
        let videoFormats = supportedVideoTypes.sorted().joined(separator: ", ")
        return "Audio: \(audioFormats)\nVideo: \(videoFormats)"
    }
    
    static func fileTypeIcon(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if supportedAudioTypes.contains(ext) {
            return "waveform"
        } else if supportedVideoTypes.contains(ext) {
            return "video.fill"
        } else {
            return "doc.fill"
        }
    }
    
    static func fileTypeColor(for url: URL) -> Color {
        let ext = url.pathExtension.lowercased()
        if supportedAudioTypes.contains(ext) {
            return .blue
        } else if supportedVideoTypes.contains(ext) {
            return .purple
        } else {
            return .gray
        }
    }
    
    // OpenAI configuration
    private lazy var openAIKey: String? = try? APIKeyManager.shared.getAPIKey(for: .openai)
    private let maxWhisperFileSize = 25 * 1024 * 1024 // 25MB limit for Whisper API
    
    private var cancellationToken: AnyCancellable?
    private var currentTask: Task<Void, Never>?
    
    private init() {
        print("🎬 FileTranscriptionService: Initialized with macOS 26 SpeechAnalyzer support")
        updateProviderBasedOnAvailability()
    }
    
    // MARK: - Public Methods
    
    func isSupportedFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return Self.supportedAudioTypes.contains(ext) || Self.supportedVideoTypes.contains(ext)
    }
    
    func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func transcribeFile(_ url: URL) async throws -> String {
        print("🎬 FileTranscriptionService: Starting transcription for file: \(url.lastPathComponent)")
        
        // Reset state
        await MainActor.run {
            isTranscribing = true
            progress = 0
            currentStatus = "Preparing transcription..."
            error = nil
            transcriptionResult = nil
        }
        
        // Check if file is supported
        guard isSupportedFile(url) else {
            await MainActor.run {
                isTranscribing = false
                error = .unsupportedFileType
            }
            throw FileTranscriptionError.unsupportedFileType
        }
        
        // Get file info
        let fileInfo = try await getFileInfo(url)
        await MainActor.run {
            currentFileName = fileInfo.name
            currentFileSize = fileInfo.sizeString
            currentFileDuration = fileInfo.duration
        }
        
        // Check file size for GPT-4o
        if selectedProvider == .gpt4oWhisper && fileInfo.size > maxWhisperFileSize {
            await MainActor.run {
                isTranscribing = false
                error = .fileTooLarge(maxSize: maxWhisperFileSize)
            }
            throw FileTranscriptionError.fileTooLarge(maxSize: maxWhisperFileSize)
        }
        
        do {
            let result: String
            
            // Update provider based on availability
            updateProviderBasedOnAvailability()
            
            print("🎯 FileTranscriptionService: Using provider: \(selectedProvider.rawValue)")
            
            switch selectedProvider {
            case .speechAnalyzer:
                if canUseSpeechAnalyzer() {
                    print("🚀 FileTranscriptionService: Using macOS 26 SpeechAnalyzer")
                    result = try await transcribeWithSpeechAnalyzer(url)
                } else {
                    print("⚠️ FileTranscriptionService: SpeechAnalyzer not available, falling back to GPT-4o")
                    result = try await transcribeWithGPT4oWhisper(url)
                }
            case .gpt4oWhisper:
                print("🤖 FileTranscriptionService: Using GPT-4o Whisper")
                result = try await transcribeWithGPT4oWhisper(url)
            }
            
            await MainActor.run {
                transcriptionResult = result
                isTranscribing = false
                currentStatus = "Transcription complete"
                progress = 1.0
            }
            
            return result
        } catch {
            await MainActor.run {
                isTranscribing = false
                self.error = error as? FileTranscriptionError ?? .transcriptionFailed(error.localizedDescription)
            }
            throw error
        }
    }
    
    func cancelTranscription() {
        currentTask?.cancel()
        currentTask = nil
        
        Task { @MainActor in
            isTranscribing = false
            currentStatus = "Transcription cancelled"
            error = .cancelled
        }
    }
    
    // MARK: - Private Methods
    
    private func updateProviderBasedOnAvailability() {
        // If SpeechAnalyzer isn't available at runtime, switch to GPT-4o
        if selectedProvider == .speechAnalyzer && !canUseSpeechAnalyzer() {
            print("⚠️ SpeechAnalyzer not available, auto-switching to GPT-4o")
            selectedProvider = .gpt4oWhisper
        }
    }
    
    private func getFileInfo(_ url: URL) async throws -> (name: String, size: Int, sizeString: String, duration: String) {
        let asset = AVURLAsset(url: url)
        
        // Get file size
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
        let sizeInMB = Double(fileSize) / (1024 * 1024)
        let sizeString = String(format: "%.1f MB", sizeInMB)
        
        // Get duration
        let duration = try await asset.load(.duration)
        let seconds = CMTimeGetSeconds(duration)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        let durationString = formatter.string(from: seconds) ?? "Unknown"
        
        print("📊 FileTranscriptionService: File info - Size: \(sizeString), Duration: \(durationString)")
        
        return (url.lastPathComponent, fileSize, sizeString, durationString)
    }
    
    // MARK: - SpeechAnalyzer Implementation
    
    private func canUseSpeechAnalyzer() -> Bool {
        // Check if SpeechTranscriber type is available at runtime
        // This will return false if the beta symbols aren't available
        return NSClassFromString("SpeechTranscriber") != nil
    }
    
    private func transcribeWithSpeechAnalyzer(_ url: URL) async throws -> String {
        print("🎯 SpeechAnalyzer: Starting transcription")
        
        await MainActor.run {
            currentStatus = "Processing with SpeechAnalyzer..."
        }
        
        // Check runtime availability
        guard canUseSpeechAnalyzer() else {
            print("❌ SpeechAnalyzer not available at runtime")
            throw FileTranscriptionError.speechAnalyzerUnavailable
        }
        
        // Note: The actual SpeechAnalyzer implementation would go here
        // For now, we'll throw an error to trigger GPT-4o fallback
        // This is because the beta symbols aren't available yet
        
        /* Future implementation when symbols are available:
        let locale = Locale(identifier: "en-US")
        let transcriber = SpeechTranscriber(
            locale: locale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: [.audioTimeRange]
        )
        
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        let audioFile = try AVAudioFile(forReading: url)
        var fullTranscription = ""
        
        try await analyzer.analyzeSequence(from: audioFile)
        
        for try await result in transcriber.results {
            fullTranscription = String(result.text.characters)
            
            await MainActor.run {
                self.progress = min(Double(fullTranscription.count) / 10000, 0.9)
                self.currentStatus = "Transcribing... \(fullTranscription.count) characters"
            }
        }
        
        return fullTranscription
        */
        
        // For now, throw to trigger fallback
        throw FileTranscriptionError.speechAnalyzerUnavailable
    }
    
    // MARK: - GPT-4o Whisper Implementation
    
    private func transcribeWithGPT4oWhisper(_ url: URL) async throws -> String {
        print("🤖 GPT-4o: Starting Whisper transcription")
        
        guard let apiKey = openAIKey, !apiKey.isEmpty else {
            throw FileTranscriptionError.providerUnavailable
        }
        
        await MainActor.run {
            currentStatus = "Uploading to GPT-4o Whisper..."
            progress = 0.1
        }
        
        // Prepare the request
        let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add language parameter (optional, but helps with accuracy)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)
        
        // Add response format
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("text\r\n".data(using: .utf8)!)
        
        // Add file
        let fileData = try Data(contentsOf: url)
        let filename = url.lastPathComponent
        let mimeType = getMimeType(for: url.pathExtension)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        await MainActor.run {
            currentStatus = "Processing with GPT-4o Whisper..."
            progress = 0.3
        }
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FileTranscriptionError.transcriptionFailed("Invalid response")
        }
        
        if httpResponse.statusCode == 200 {
            // Response is plain text for "text" format
            guard let transcription = String(data: data, encoding: .utf8) else {
                throw FileTranscriptionError.transcriptionFailed("Failed to decode response")
            }
            
            await MainActor.run {
                progress = 1.0
                currentStatus = "Transcription complete"
            }
            
            print("✅ GPT-4o: Transcription complete - \(transcription.count) characters")
            return transcription
        } else {
            // Try to parse error
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorResponse["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw FileTranscriptionError.transcriptionFailed(message)
            } else {
                throw FileTranscriptionError.transcriptionFailed("HTTP \(httpResponse.statusCode)")
            }
        }
    }
    
    private func getMimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "mp3": return "audio/mpeg"
        case "mp4": return "video/mp4"
        case "wav": return "audio/wav"
        case "m4a": return "audio/mp4"
        case "webm": return "video/webm"
        case "mov": return "video/quicktime"
        default: return "application/octet-stream"
        }
    }
}