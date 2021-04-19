//
//  APIClient.swift
//  
//
//  Created by Yusaku Nishi on 2020/10/23.
//

import Alamofire
import Foundation

public struct APIClient {
    
    private init() {}
    
    /// A default decoder used to decode JSON in the `APIClient.send(_:, decodingCompletion:)` method.
    ///
    /// You can use this property when you want to use a common decoder in your app.
    /// If you want to use a different decoder for each request,
    /// implement the `preferredJSONDecoder` property in the request type that conforms to the `DecodingRequest` protocol.
    public static let defaultJSONDecoder = JSONDecoder()
    
    public static func send<Request: APIRequest>(_ request: Request,
                                                 completion: @escaping (Result<Data?, AFError>) -> Void) {
        request.alamofireRequest.response { response in
            completion(response.result)
        }
    }
    public static func send<Request: DecodingRequest>(_ request: Request,
                                                      decodingCompletion: @escaping (Result<Request.Response, Error>) -> Void) {
        request.alamofireRequest
            .responseData { response in
                let result: Result<Request.Response, Error>
                defer { decodingCompletion(result) }
                
                switch response.result {
                case .success(let data):
                    do {
                        let decoder = Request.preferredJSONDecoder ?? defaultJSONDecoder
                        let decoded = try decoder.decode(Request.Response.self, from: data)
                        result = .success(decoded)
                    } catch {
                        result = .failure(error)
                    }
                case .failure(let error):
                    result = .failure(error)
                }
        }
    }
}

extension APIRequest {
    
    var alamofireRequest: DataRequest {
        AF.request(urlComponents,
                   method: Self.httpMethod,
                   parameters: (self as? Postable)?.body,
                   encoding: JSONEncoding.default,
                   headers: headers)
            .validate(statusCode: acceptableStatusCodes)
    }
}
