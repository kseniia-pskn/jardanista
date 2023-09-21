//
//  RequestProcessor.swift
//  Jardanista
//
//  Created by Kseniia Piskun on 11.09.2023.
//

import SwiftUI

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case httpResponseError(Int, String)
    case dataParsingError(Error)
}

class RequestProcessor: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, ObservableObject {
    let plantInfoFetcher = PlantInfoFetcher()
    @Binding var isCoordinatorShown: Bool
    @Binding var imageInCoordinator: Image?
    @Binding var showProgress: Bool
    @Binding var commonName: String
    @Binding var plantName: String
    @Binding var probability: String
    @Binding var plantDescription: String
    
    init(isShown: Binding<Bool>, image: Binding<Image?>, showProgress: Binding<Bool>, commonName: Binding<String>, plantName: Binding<String>, probability: Binding<String>, plantDescription: Binding<String>) {
        _isCoordinatorShown = isShown
        _imageInCoordinator = image
        _showProgress = showProgress
        _commonName = commonName
        _plantName = plantName
        _probability = probability
        _plantDescription = plantDescription
        NSLog("Coordinator instantiated")
    }
    
    // Add an instance variable to store the selected image.
    private var unwrappedImage: UIImage?
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let unwrappedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            NSLog("Failed to unwrap image")
            return
        }
        NSLog("In imagePickerController unwrappedImage obtained")
        
        Task {
            await self.postData(image: unwrappedImage, postDataCompletionHandler: { [self] jsonData, error in
                if let error = error {
                    self.handleError(error)
                    return
                }
                
                guard let jsonData = jsonData else {
                    self.handleError(NetworkError.invalidResponse)
                    return
                }
                
                print("In imagePickerController postDataCompletionHandler got responseDictionary:\n\(jsonData)")
                
                if let result = jsonData["result"] as? [String: Any],
                   let classification = result["classification"] as? [String: Any],
                   let suggestions = classification["suggestions"] as? [[String: Any]],
                   let firstSuggestion = suggestions.first{
                    if  let name = firstSuggestion["name"] as? String {
                        self.plantName = name
                    }
                    
                    if let probability = firstSuggestion["probability"] as? Double {
                        self.probability = "Confidence: \(String(format: "%.1f", probability * 100.0))%"
                    }
                    
                    let plantNameToSearch = self.plantName
                    plantInfoFetcher.fetchPlantInfo(for: plantNameToSearch) { result in
                        switch result {
                        case .success(let info):
                            self.commonName = info.commonName
                            self.plantDescription  = info.description
                            print("Common Name: \(self.commonName)")
                            print("Description: \(self.plantDescription)")
                        case .failure(let error):
                            print("Error: \(error.localizedDescription)")
                        }
                    }
                }
                
                self.showProgress = false
            })
        }
        imageInCoordinator = Image(uiImage: unwrappedImage)
        isCoordinatorShown = false
        showProgress = true
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isCoordinatorShown = false
        showProgress = false
    }
    
    func deserializeData(from jsonString: String) -> [String: AnyObject] {
        NSLog("In deserializeData got jsonString: \(jsonString)")
        guard let jsonData = jsonString.data(using: .utf8) else {
            NSLog("In deserializeData fail to get jsonData")
            return [String: AnyObject]()
        }
        guard let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: AnyObject] else {
            NSLog("In deserializeData fail to decode JSON string")
            return [String: AnyObject]()
        }
        return json
    }
    
    func postData(image: UIImage, postDataCompletionHandler: @escaping ([String: AnyObject]?, NetworkError?) -> Void) async {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            NSLog("Invalid image data")
            postDataCompletionHandler(nil, NetworkError.invalidResponse)
            return
        }
        NSLog("In postData generated imageData: \(type(of: imageData)) \(imageData)")
        
        let apiKey = "OypFfeEr9fHbKahifaf6zoswmfk6lNSw6nf8rSoGuPnX4exZ8T"
        let urlString = "https://plant.id/api/v3/identification"
        
        let parameters: [String: Any] = [
            "similar_images": true,
            "latitude": Float(),
            "longitude": Float(),
            "images": [imageData.base64EncodedString()]
        ]
        
            
        do {
            let result = try await makePOSTRequest(urlString: urlString, apiKey: apiKey, imageData: imageData, parameters: parameters)
            
            switch result {
            case .success(let data):
                let jsonString = String(data: data, encoding: .utf8)!
                let json = self.deserializeData(from: jsonString)
                print("In postData got response JSON object:\n\(json)")
                postDataCompletionHandler(json, nil)
            case .failure(let error):
                postDataCompletionHandler(nil, error)
            }
        } catch {
            postDataCompletionHandler(nil, NetworkError.requestFailed(error))
        }
    }
    
    func makePOSTRequest(urlString: String, apiKey: String, imageData: Data, parameters: [String: Any]) async throws -> Result<Data, NetworkError> {
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "Api-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Print request body and headers for debugging
        if let body = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            print("Request Body: \(body)")
        }
        
        if let headers = request.allHTTPHeaderFields {
            print("Request Headers: \(headers)")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return .failure(.invalidResponse)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let jsonData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let accessToken = jsonData["access_token"] as? String {
                    print("Access Token: \(accessToken)")
                } else {
                    print("Access Token not found or is not a string")
                }
                
                if let modelVersion = jsonData["model_version"] as? String {
                    print("Model Version: \(modelVersion)")
                } else {
                    print("Model Version not found or is not a string")
                }
                
                if let input = jsonData["input"] as? [String: Any] {
                    // Access fields inside the "input" dictionary
                    if let latitude = input["latitude"] as? Double {
                        print("Latitude: \(latitude)")
                    } else {
                        print("Latitude not found or is not a double")
                    }
                    
                    if let longitude = input["longitude"] as? Double {
                        print("Longitude: \(longitude)")
                    } else {
                        print("Longitude not found or is not a double")
                    }
                    
                    // Continue accessing other fields inside the "input" dictionary
                } else {
                    print("Input data not found or is not a dictionary")
                }
                
                // Continue accessing and typecasting other fields in a similar manner
            } else {
                print("Failed to parse JSON data or JSON data is not a dictionary")
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            if httpResponse.statusCode == 400 || httpResponse.statusCode == 401 {
                if let responseBody = String(data: data, encoding: .utf8) {
                    NSLog("HTTP response error with status code: \(httpResponse.statusCode)")
                    NSLog("Reason: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
                    NSLog("Response Body: \(responseBody)")
                } else {
                    NSLog("HTTP response error with status code: \(httpResponse.statusCode)")
                    NSLog("Reason: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
                    NSLog("Response Body: Unable to decode response data")
                }
                return .failure(.httpResponseError(httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)))
            }
            
            return .success(data)
        } catch {
            return .failure(.requestFailed(error))
        }
    }
 
    func handleError(_ error: NetworkError) {
        switch error {
        case .invalidURL:
            NSLog("Invalid URL")
        case .requestFailed(let underlyingError):
            NSLog("Request failed with error: \(underlyingError.localizedDescription)")
        case .invalidResponse:
            NSLog("Invalid response")
        case .httpResponseError(let statusCode, let reason):
            NSLog("HTTP response error with status code: \(statusCode)")
            NSLog("Reason: \(reason)")
        case .dataParsingError(let parsingError):
            NSLog("Data parsing error: \(parsingError.localizedDescription)")
        }
    }
}



class PlantInfoFetcher {
    func fetchPlantInfo(for plantName: String, completion: @escaping (Result<(commonName: String, description: String), Error>) -> Void) {
        // Construct the Wikipedia search URL based on the plant name.
        guard let escapedPlantName = plantName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        let wikipediaSearchURLString = "https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exintro=true&explaintext=true&titles=\(escapedPlantName)"
        
        guard let wikipediaSearchURL = URL(string: wikipediaSearchURLString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        // Create a URLSession data task to fetch the plant description.
        let task = URLSession.shared.dataTask(with: wikipediaSearchURL) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            do {
                // Parse the JSON response to extract the plant description.
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let query = json?["query"] as? [String: Any],
                   let pages = query["pages"] as? [String: Any],
                   let firstPage = pages.first?.value as? [String: Any],
                   let description = firstPage["extract"] as? String {
                    completion(.success((commonName: plantName, description: description)))
                } else {
                    completion(.failure(NetworkError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

}
