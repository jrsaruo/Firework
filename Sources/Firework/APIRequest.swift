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
