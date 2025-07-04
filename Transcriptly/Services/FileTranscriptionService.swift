//
//  FileTranscriptionService.swift
//  Transcriptly
//
//  Service for transcribing audio and video files using Apple Speech or cloud AI
//

import Foundation
import Speech
import AVFoundation
import Combine
import SwiftUI

enum FileTranscriptionProvider: String, CaseIterable {
    case appleSpeech = "Apple Speech"
    case gpt4oTranscribe = "GPT-4o Transcribe"
    
    var description: String {
        switch self {
        case .appleSpeech:
            return "Local, private, fast transcription"
        case .gpt4oTranscribe:
            return "Cloud-based, highest accuracy"
        }
    }
    
    var icon: String {
        switch self {
        case .appleSpeech:
            return "waveform.badge.mic"
        case .gpt4oTranscribe:
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
    
    // Provider selection comes from AIProviderManager
    private var selectedProvider: FileTranscriptionProvider {
        // For now, default to Apple Speech - will integrate with AIProviderManager later
        return .appleSpeech
    }
    
    // File information
    @Published var currentFileName: String?
    @Published var currentFileSize: String?
    @Published var currentFileDuration: String?
    
    // Supported file types
    static let supportedAudioTypes: Set<String> = ["mp3", "wav", "m4a", "aac", "flac", "ogg"]
    static let supportedVideoTypes: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv", "webm"]
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var cancellationToken: AnyCancellable?
    
    private init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        print("🎬 FileTranscriptionService: Initialized with recognizer available: \(speechRecognizer?.isAvailable ?? false)")
        print("🔐 FileTranscriptionService: Speech authorization status: \(SFSpeechRecognizer.authorizationStatus().rawValue)")
    }
    
    // MARK: - Public Methods
    
    func requestSpeechPermissions() async -> Bool {
        print("🔐 FileTranscriptionService: Requesting speech recognition permissions...")
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                print("🔐 FileTranscriptionService: Permission result: \(status.rawValue)")
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
            error = nil
            transcriptionResult = nil
            currentStatus = "Preparing file..."
        }
        
        // Validate file
        guard FileTranscriptionService.isSupported(url) else {
            print("❌ FileTranscriptionService: Unsupported file type: \(url.pathExtension)")
            throw FileTranscriptionError.unsupportedFileType
        }
        print("✅ FileTranscriptionService: File type supported: \(url.pathExtension)")
        
        // Get file info
        let fileInfo = try getFileInfo(url)
        print("📊 FileTranscriptionService: File info - Size: \(fileInfo.sizeString), Duration: \(fileInfo.durationString ?? "unknown")")
        
        await MainActor.run {
            currentFileName = fileInfo.name
            currentFileSize = fileInfo.sizeString
            currentFileDuration = fileInfo.durationString
        }
        
        // Check file size based on provider
        let maxSize = selectedProvider == .appleSpeech ? 7 * 1024 * 1024 * 1024 : 25 * 1024 * 1024
        print("📏 FileTranscriptionService: File size check - Size: \(fileInfo.size), Max: \(maxSize), Provider: \(selectedProvider)")
        if fileInfo.size > maxSize {
            print("❌ FileTranscriptionService: File too large for provider \(selectedProvider)")
            throw FileTranscriptionError.fileTooLarge(maxSize: maxSize)
        }
        
        // Check and request permissions if using Apple Speech
        if selectedProvider == .appleSpeech {
            let authStatus = SFSpeechRecognizer.authorizationStatus()
            if authStatus == .notDetermined {
                print("🔐 FileTranscriptionService: Requesting speech permissions...")
                let granted = await requestSpeechPermissions()
                if !granted {
                    print("❌ FileTranscriptionService: Speech permissions denied")
                    throw FileTranscriptionError.transcriptionFailed("Speech recognition permission denied")
                }
            } else if authStatus != .authorized {
                print("❌ FileTranscriptionService: Speech permissions not authorized: \(authStatus.rawValue)")
                throw FileTranscriptionError.transcriptionFailed("Speech recognition not authorized")
            }
        }
        
        // Perform transcription based on provider
        print("🚀 FileTranscriptionService: Starting transcription with provider: \(selectedProvider)")
        do {
            let result: String
            switch selectedProvider {
            case .appleSpeech:
                print("🍎 FileTranscriptionService: Using Apple Speech Recognition")
                result = try await transcribeWithAppleSpeech(url)
            case .gpt4oTranscribe:
                print("🤖 FileTranscriptionService: Using GPT-4o Transcribe")
                result = try await transcribeWithGPT4o(url)
            }
            
            print("✅ FileTranscriptionService: Transcription completed, result length: \(result.count) characters")
            
            await MainActor.run {
                transcriptionResult = result
                isTranscribing = false
                currentStatus = "Transcription complete"
            }
            
            return result
        } catch {
            print("❌ FileTranscriptionService: Transcription failed with error: \(error)")
            await MainActor.run {
                isTranscribing = false
                if let fileError = error as? FileTranscriptionError {
                    self.error = fileError
                } else {
                    self.error = .transcriptionFailed(error.localizedDescription)
                }
            }
            throw error
        }
    }
    
    func cancelTranscription() {
        recognitionTask?.cancel()
        cancellationToken?.cancel()
        
        Task { @MainActor in
            isTranscribing = false
            error = .cancelled
            currentStatus = "Transcription cancelled"
        }
    }
    
    // MARK: - File Validation
    
    static func isSupported(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return supportedAudioTypes.contains(fileExtension) || supportedVideoTypes.contains(fileExtension)
    }
    
    static func supportedFormatsString() -> String {
        let audioFormats = supportedAudioTypes.sorted().map { $0.uppercased() }
        let videoFormats = supportedVideoTypes.sorted().map { $0.uppercased() }
        return "Audio: \(audioFormats.joined(separator: ", "))\nVideo: \(videoFormats.joined(separator: ", "))"
    }
    
    // MARK: - Private Methods
    
    private func getFileInfo(_ url: URL) throws -> (name: String, size: Int, sizeString: String, durationString: String?) {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let size = attributes[.size] as? Int ?? 0
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        let sizeString = formatter.string(fromByteCount: Int64(size))
        
        // Get duration for audio/video files
        var durationString: String?
        let asset = AVAsset(url: url)
        
        // For video files, ensure we have audio tracks
        let audioTracks = asset.tracks(withMediaType: .audio)
        print("🎬 FileTranscriptionService: Asset has \(audioTracks.count) audio tracks")
        
        if audioTracks.isEmpty {
            print("⚠️ FileTranscriptionService: No audio tracks found in video file")
        }
        
        // Note: Using deprecated API for now - will migrate to async load later
        if asset.duration.isValid && !asset.duration.isIndefinite {
            let duration = CMTimeGetSeconds(asset.duration)
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            durationString = String(format: "%d:%02d", minutes, seconds)
        }
        
        return (url.lastPathComponent, size, sizeString, durationString)
    }
    
    private func transcribeWithAppleSpeech(_ url: URL) async throws -> String {
        print("🍎 Apple Speech: Checking recognizer availability...")
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("❌ Apple Speech: Recognizer not available")
            throw FileTranscriptionError.providerUnavailable
        }
        print("✅ Apple Speech: Recognizer available for locale: \(recognizer.locale.identifier)")
        
        // Check Speech Recognition permissions
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        print("🔐 Apple Speech: Authorization status: \(authStatus.rawValue)")
        
        if authStatus != .authorized {
            print("❌ Apple Speech: Not authorized for speech recognition")
            throw FileTranscriptionError.transcriptionFailed("Speech recognition not authorized")
        }
        
        await MainActor.run {
            currentStatus = "Processing with Apple Speech..."
        }
        
        print("🎯 Apple Speech: Creating recognition request for file: \(url.lastPathComponent)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = true
            request.requiresOnDeviceRecognition = false // Allow cloud processing for better accuracy
            request.taskHint = .unspecified // Let the system determine the best approach
            
            print("📝 Apple Speech: Starting recognition task...")
            
            var finalTranscription = ""
            var lastUpdateTime = Date()
            var hasResumed = false
            
            recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let result = result {
                    finalTranscription = result.bestTranscription.formattedString
                    let segmentCount = result.bestTranscription.segments.count
                    
                    print("🔄 Apple Speech: Partial result - \(finalTranscription.count) chars, \(segmentCount) segments, isFinal: \(result.isFinal)")
                    
                    // Update progress based on time
                    let now = Date()
                    if now.timeIntervalSince(lastUpdateTime) > 0.5 {
                        Task { @MainActor in
                            // Estimate progress based on partial results
                            self.progress = min(0.9, self.progress + 0.1)
                            self.currentStatus = "Transcribing... \(Int(self.progress * 100))%"
                            print("📊 Apple Speech: Progress updated to \(Int(self.progress * 100))%")
                        }
                        lastUpdateTime = now
                    }
                    
                    if result.isFinal {
                        print("✅ Apple Speech: Final result received - \(finalTranscription.count) characters")
                        Task { @MainActor in
                            self.progress = 1.0
                        }
                        if !hasResumed {
                            hasResumed = true
                            // Check if we actually got any transcription
                            if finalTranscription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                continuation.resume(throwing: FileTranscriptionError.transcriptionFailed("No speech detected in the file. Please ensure the file contains clear audio."))
                            } else {
                                continuation.resume(returning: finalTranscription)
                            }
                        }
                    }
                }
                
                if let error = error {
                    print("❌ Apple Speech: Recognition error: \(error.localizedDescription)")
                    if !hasResumed {
                        hasResumed = true
                        // Provide more helpful error messages
                        let errorMessage: String
                        if error.localizedDescription.contains("No speech detected") {
                            errorMessage = "No speech detected in the file. Please ensure the file contains clear audio."
                        } else if error.localizedDescription.contains("cancelled") {
                            errorMessage = "Transcription was cancelled."
                        } else {
                            errorMessage = error.localizedDescription
                        }
                        continuation.resume(throwing: FileTranscriptionError.transcriptionFailed(errorMessage))
                    }
                }
            }
            
            if recognitionTask == nil {
                print("❌ Apple Speech: Failed to create recognition task")
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: FileTranscriptionError.transcriptionFailed("Failed to create recognition task"))
                }
            } else {
                print("✅ Apple Speech: Recognition task created successfully")
            }
            
            self.recognitionRequest = request
        }
    }
    
    private func transcribeWithGPT4o(_ url: URL) async throws -> String {
        await MainActor.run {
            currentStatus = "Uploading to GPT-4o..."
        }
        
        // For now, return a placeholder since we need to implement the actual API call
        // This would involve:
        // 1. Reading the file data
        // 2. Potentially chunking if > 25MB
        // 3. Making API call to OpenAI
        // 4. Processing the response
        
        // Simulate progress
        for i in 0...10 {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            await MainActor.run {
                progress = Double(i) / 10.0
                currentStatus = "Processing with GPT-4o... \(Int(progress * 100))%"
            }
        }
        
        throw FileTranscriptionError.providerUnavailable
    }
}

// MARK: - File Type Detection

extension FileTranscriptionService {
    static func fileTypeIcon(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        
        if supportedVideoTypes.contains(ext) {
            return "video.fill"
        } else if supportedAudioTypes.contains(ext) {
            return "waveform"
        } else {
            return "doc.fill"
        }
    }
    
    static func fileTypeColor(for url: URL) -> Color {
        let ext = url.pathExtension.lowercased()
        
        if supportedVideoTypes.contains(ext) {
            return Color.purple
        } else if supportedAudioTypes.contains(ext) {
            return Color.blue
        } else {
            return Color.gray
        }
    }
}