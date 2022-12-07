//
//  HTTPRequest.swift
//  
//
//  Created by Yusaku Nishi on 2020/10/23.
//

import Alamofire
import Foundation

@available(*, unavailable, renamed: "HTTPRequest")
public protocol APIRequest {}

public protocol HTTPRequest {
    associatedtype StatusCodes: Sequence where StatusCodes.Element == Int
    associatedtype ContentTypes: Sequence where ContentTypes.Element == String
    
    static var httpMethod: HTTPMethod { get }
    var endpoint: Endpoint { get }
    var headers: HTTPHeaders? { get }
    var queryItems: [URLQueryItem]? { get }
    var acceptableStatusCodes: StatusCodes { get }
    var acceptableContentTypes: ContentTypes { get }
}

public extension HTTPRequest {
    
    var headers: HTTPHeaders? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var acceptableStatusCodes: Range<Int> { 200..<400 }
    
    var acceptableContentTypes: [String] {
        headers?["Accept"]?.components(separatedBy: ",") ?? ["*/*"]
    }
    
    /// URL component to pass to Alamofire.
    var urlComponents: URLComponents {
        guard var urlComponents = URLComponents(string: endpoint.urlString) else {
            preconditionFailure("\(endpoint.urlString) is an invalid URL. Please check \(Self.self) endpoint.")
        }
        urlComponents.queryItems = queryItems
        return urlComponents
    }
}

@available(*, unavailable, renamed: "HTTPBodySendable")
public protocol Postable {}

public protocol HTTPBodySendable {
    var body: [String: Any] { get }
}

// MARK: - GETRequest

public protocol GETRequest: HTTPRequest {}

public extension GETRequest {
    static var httpMethod: HTTPMethod { .get }
}

// MARK: - POSTRequest

public protocol POSTRequest: HTTPRequest, HTTPBodySendable {}

public extension POSTRequest {
    static var httpMethod: HTTPMethod { .post }
}

// MARK: - PUTRequest

public protocol PUTRequest: HTTPRequest, HTTPBodySendable {}

public extension PUTRequest {
    static var httpMethod: HTTPMethod { .put }
}

// MARK: - PATCHRequest

public protocol PATCHRequest: HTTPRequest, HTTPBodySendable {}

public extension PATCHRequest {
    static var httpMethod: HTTPMethod { .patch }
}

// MARK: - DELETERequest

public protocol DELETERequest: HTTPRequest {}

public extension DELETERequest {
    static var httpMethod: HTTPMethod { .delete }
}

// MARK: - DecodingRequest

public protocol DecodingRequest: HTTPRequest {
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
