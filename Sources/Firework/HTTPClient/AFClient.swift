//
//  AFClient.swift
//  
//
//  Created by Yusaku Nishi on 2022/03/12.
//

import Alamofire
import Foundation

// MARK: - AlamofireAdaptor -

public struct AlamofireAdaptor: HTTPClientAdaptor {
    
    public func send(_ request: some HTTPRequest,
                     receiveOn queue: DispatchQueue = .main,
                     completion: @escaping (Result<Data?, AFError>) -> Void) {
        makeDataRequest(from: request).response(queue: queue) { response in
            completion(response.result)
        }
    }
    
    public func send(_ request: some HTTPRequest,
                     receiveOn queue: DispatchQueue = .main,
                     completion: @escaping (Result<Data, AFError>) -> Void) {
        makeDataRequest(from: request).responseData(queue: queue) { response in
            completion(response.result)
        }
    }
    
    private func makeDataRequest<Request: HTTPRequest>(from request: Request) -> DataRequest {
        AF.request(request.urlComponents,
                   method: Request.httpMethod,
                   parameters: (request as? HTTPBodySendable)?.body,
                   encoding: JSONEncoding.default,
                   headers: request.headers)
            .validate(statusCode: request.acceptableStatusCodes)
            .validate(contentType: request.acceptableContentTypes)
    }
}

public extension HTTPClientAdaptor where Self == AlamofireAdaptor {
    static var alamofire: Self { AlamofireAdaptor() }
}

// MARK: - AFClient -

/// An HTTP client using Alamofire.
public typealias AFClient = HTTPClient<AlamofireAdaptor>

extension AFClient {
    
    /// Creates an ``AFClient`` instance.
    /// - Parameter configuration: A configuration used for HTTP communication. The default is `.shared`.
    public init(configuration: HTTPClientConfiguration = .shared) {
        self.init(configuration: configuration, adaptor: .alamofire)
    }
}
