//
//  AudioService.swift
//  Transcriptly
//
//  Created by Claude Code on 6/25/25.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioService: ObservableObject {
    private nonisolated(unsafe) var audioRecorder: AVAudioRecorder?
    
    @Published var isRecording = false
    @Published var recordingError: String?
    
    init() {
        // No audio session setup needed on macOS - AVAudioRecorder handles it
    }
    
    private func resetAudioSessionState() {
        // On macOS, we don't need to manage AVAudioSession explicitly
        // AVAudioRecorder will handle the audio session internally
        recordingError = nil
    }
    
    func startRecording() async -> Bool {
        // Reset any previous error state
        resetAudioSessionState()
        
        // Create temporary file URL for recording
        let tempDirectory = FileManager.default.temporaryDirectory
        let recordingURL = tempDirectory.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        // Audio settings optimized for speech
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.prepareToRecord()
            
            let success = audioRecorder?.record() ?? false
            
            await MainActor.run {
                isRecording = success
                if !success {
                    recordingError = "Failed to start recording"
                } else {
                    recordingError = nil
                }
            }
            
            return success
        } catch {
            await MainActor.run {
                isRecording = false
                recordingError = "Recording setup failed: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    func stopRecording() async -> URL? {
        guard let recorder = audioRecorder, isRecording else {
            await MainActor.run {
                recordingError = "No active recording to stop"
            }
            return nil
        }
        
        recorder.stop()
        
        await MainActor.run {
            isRecording = false
        }
        
        // On macOS, no explicit audio session cleanup needed
        // AVAudioRecorder handles session lifecycle automatically
        
        let recordingURL = recorder.url
        audioRecorder = nil
        
        // Verify the file exists and has content
        if FileManager.default.fileExists(atPath: recordingURL.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: recordingURL.path)
                if let fileSize = attributes[.size] as? Int64, fileSize > 0 {
                    return recordingURL
                } else {
                    await MainActor.run {
                        recordingError = "Recording file is empty"
                    }
                    return nil
                }
            } catch {
                await MainActor.run {
                    recordingError = "Failed to verify recording file: \(error.localizedDescription)"
                }
                return nil
            }
        } else {
            await MainActor.run {
                recordingError = "Recording file was not created"
            }
            return nil
        }
    }
    
    func cancelRecording() async {
        guard let recorder = audioRecorder, isRecording else { return }
        
        recorder.stop()
        
        // Delete the recording file
        let recordingURL = recorder.url
        try? FileManager.default.removeItem(at: recordingURL)
        
        await MainActor.run {
            isRecording = false
            recordingError = nil
        }
        
        // On macOS, no explicit audio session cleanup needed
        // AVAudioRecorder handles session lifecycle automatically
        
        audioRecorder = nil
    }
    
    deinit {
        // Ensure cleanup on deinit - safe with nonisolated(unsafe)
        audioRecorder?.stop()
        // On macOS, no explicit audio session cleanup needed
    }
}