import Foundation
import SwiftUI

enum AppStep {
    case selectImage
    case selectDevice
    case confirmAndWrite
    case inProgress
    case completed
    case failed
}

@MainActor
@Observable
class AppState {
    var currentStep: AppStep = .selectImage
    var selectedImageURL: URL?
    var imageSize: UInt64 = 0
    var selectedDevice: USBDevice?
    var devices: [USBDevice] = []
    var flashState: FlashState = .idle
    var estimatedTimeRemaining: TimeInterval?
    var errorMessage: String = ""
    var showError: Bool = false
    var writeStartTime: Date?
    
    var canSelectDevice: Bool {
        selectedImageURL != nil
    }
    
    var canStartWrite: Bool {
        selectedImageURL != nil && selectedDevice != nil && !isWriting
    }
    
    var isWriting: Bool {
        if case .writing = flashState { return true }
        if case .preparing = flashState { return true }
        if case .verifying = flashState { return true }
        return false
    }
    
    func reset() {
        currentStep = .selectImage
        selectedImageURL = nil
        imageSize = 0
        selectedDevice = nil
        flashState = .idle
        estimatedTimeRemaining = nil
        errorMessage = ""
        showError = false
        writeStartTime = nil
    }
}
