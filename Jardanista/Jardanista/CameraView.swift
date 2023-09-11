//
//  CameraView.swift
//  Jardanista
//
//  Created by Kseniia Piskun on 11.09.2023.
//

import SwiftUI
import AVFoundation

struct CameraView {
    
    /// MARK: - Properties
    @Binding var isShown: Bool
    @Binding var image: Image?
    @Binding var showProgress: Bool
    @Binding var commonName: String
    @Binding var plantName: String
    @Binding var probability: String
    @Binding var plantDescription: String
    
    func makeCoordinator() -> RequestProcessor {
        NSLog("CameraView makeCoordinator invoked")
        return RequestProcessor(isShown: $isShown, image: $image, showProgress: $showProgress,commonName: $commonName, plantName: $plantName, probability: $probability, plantDescription: $plantDescription)
    }
}

extension CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    let picker = UIImagePickerController()
                    NSLog("CameraView UIImagePickerController instantiated")
                    picker.delegate = context.coordinator
                    NSLog("CameraView UIImagePickerController delegate coordinator assigned")
                    picker.sourceType = UIImagePickerController.SourceType.camera
                   
                } else {
                    // Access denied, handle this case
                }
            }
        } else if status == .authorized {
            NSLog("CameraView UIImagePickerController instantiated")
            picker.delegate = context.coordinator
            NSLog("CameraView UIImagePickerController delegate coordinator assigned")
            picker.sourceType = UIImagePickerController.SourceType.camera
        } else {
            // Access denied, handle this case
        }
        return picker
    }
  
    func updateUIViewController(_ uiViewController: UIImagePickerController,
                              context: UIViewControllerRepresentableContext<CameraView>) {
    
    }
}

