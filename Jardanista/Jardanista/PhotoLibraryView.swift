//
//  PhotoLibraryView.swift
//  Jardanista
//
//  Created by Kseniia Piskun on 11.09.2023.
//

import SwiftUI

struct PhotoLibraryView {
  
    /// MARK: - Properties
    @Binding var isShown: Bool
    @Binding var image: Image?
    @Binding var showProgress: Bool
    @Binding var commonName: String
    @Binding var plantName: String
    @Binding var probability: String
    @Binding var plantDescription: String
  
    func makeCoordinator() -> RequestProcessor {
        NSLog("PhotoLibraryView makeCoordinator invoked")
        return RequestProcessor(isShown: $isShown, image: $image, showProgress: $showProgress,commonName: $commonName, plantName: $plantName, probability: $probability, plantDescription: $plantDescription)
    }
}

extension PhotoLibraryView: UIViewControllerRepresentable {
    func makeUIViewController(context: UIViewControllerRepresentableContext<PhotoLibraryView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        NSLog("PhotoLibraryView UIImagePickerController instantiated")
        picker.delegate = context.coordinator
        NSLog("PhotoLibraryView UIImagePickerController delegate coordinator assigned")
        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
        return picker
    }
  
    func updateUIViewController(_ uiViewController: UIImagePickerController,
                              context: UIViewControllerRepresentableContext<PhotoLibraryView>) {
    
    }
}

