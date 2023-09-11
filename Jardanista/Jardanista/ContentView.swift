//
//  ContentView.swift
//  Jardanista
//
//  Created by Kseniia Piskun on 11.09.2023.
//

import SwiftUI

struct ContentView: View {
    
    @State private var image: Image? = Image("icon")
    @State private var commonName: String = "JardanistApp"
    @State private var plantName: String = ""
    @State private var probability: String = ""
    @State private var plantDescription: String = ""
    
    @State private var showPhotoLibraryView: Bool = false
    @State private var showCameraView: Bool = false
    @State private var showProgressView: Bool = false
    
    let backgroundColor = Color(red: 224 / 255, green: 232 / 255, blue: 216 / 255) // A soft greenish-gray background color
    let primaryTextColor = Color(red: 70 / 255, green: 80 / 255, blue: 72 / 255) // A deep green for primary text
    let secondaryTextColor = Color(red: 126 / 255, green: 143 / 255, blue: 110 / 255) // A lighter green for secondary text
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                if showProgressView {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: primaryTextColor))
                        .scaleEffect(1.5)
                        .padding(.bottom, 20)
                }
                
                VStack(spacing: 10) {
                    Text(plantName)
                        .font(.custom("Avenir Next", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                        .padding(.top, 5)

                    Text(commonName)
                        .font(.custom("Avenir Next", size: 36))
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                        .padding(.top, 5)
                    
                    Text(probability)
                        .italic()
                        .font(.custom("Avenir Next", size: 18))
                        .foregroundColor(primaryTextColor)
                        .padding(.top, 5)
                }

                image?
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 350)
                    .cornerRadius(40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(primaryTextColor, lineWidth: 4)
                    )
                    .shadow(radius: 10)
                    .padding(.top, 20)
                
                Text(plantDescription)
                    .italic()
                    .font(.custom("Avenir Next", size: 18))
                    .foregroundColor(primaryTextColor)
                    .padding(.top, 5)
                
                Spacer()
                
                HStack(spacing: 15) {
                    Button(action: {
                        self.showCameraView.toggle()
                    }) {
                        Text("Capture by Camera")
                            .font(.custom("Avenir Next", size: 18))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                            .background(primaryTextColor)
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        self.showPhotoLibraryView.toggle()
                    }) {
                        Text("Select from Photos")
                            .font(.custom("Avenir Next", size: 18))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                            .background(primaryTextColor)
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showPhotoLibraryView) {
                PhotoLibraryView(isShown: $showPhotoLibraryView, image: $image, showProgress: $showProgressView, commonName: $commonName, plantName: $plantName, probability: $probability, plantDescription: $plantDescription)
            }
            
            if showCameraView {
                CameraView(isShown: $showCameraView, image: $image, showProgress: $showProgressView, commonName: $commonName, plantName: $plantName, probability: $probability, plantDescription: $plantDescription)
                    .statusBar(hidden: true)
            }
        }
    }
}
