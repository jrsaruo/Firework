//
//  APIRequest.swift
//  
//
//  Created by Yusaku Nishi on 2020/10/23.
//

import Alamofire
import Foundation

public protocol APIRequest {
    static var httpMethod: HTTPMethod { get }
    var endpoint: Endpoint { get }
    var headers: HTTPHeaders? { get }
    var queryItems: [URLQueryItem]? { get }
    var acceptableStatusCodes: Range<Int> { get }
}

public extension APIRequest {
    
    var headers: HTTPHeaders? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var acceptableStatusCodes: Range<Int> { 200..<300 }
    
    /// URL component to pass to Alamofire.
    var urlComponents: URLComponents {
        guard var urlComponents = URLComponents(string: endpoint.urlString) else {
            print("Invalid endpoint:", endpoint.urlString)
            preconditionFailure("\(endpoint.urlString) is an invalid URL. Please check \(Self.self) endpoint.")
        }
        urlComponents.queryItems = queryItems
        return urlComponents
    }
}

public protocol Postable {
    var body: [String: Any] { get }
}

// MARK: - GETRequest

public protocol GETRequest: APIRequest {}

public extension GETRequest {
    static var httpMethod: HTTPMethod { return .get }
}

// MARK: - POSTRequest

public protocol POSTRequest: APIRequest, Postable {}

public extension POSTRequest {
    static var httpMethod: HTTPMethod { return .post }
}

// MARK: - PUTRequest

public protocol PUTRequest: APIRequest, Postable {}

public extension PUTRequest {
    static var httpMethod: HTTPMethod { return .put }
}

// MARK: - PUTRequest

public protocol DELETERequest: APIRequest {}

public extension DELETERequest {
    static var httpMethod: HTTPMethod { return .delete }
}

// MARK: - DecodingRequest

public protocol DecodingRequest: APIRequest {
    associatedtype Response: Decodable
    
    /// A decoder to be used when decoding to `Response`.
    ///
    /// If nil is returned, APIClient.defaultJSONDecoder is used.
    /// The default value is nil.
    static var preferredJSONDecoder: JSONDecoder? { get }
}

public extension DecodingRequest {
    static var preferredJSONDecoder: JSONDecoder? { nil }
}
