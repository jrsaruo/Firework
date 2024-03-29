//
//  HTTPClient.swift
//  
//
//  Created by Yusaku Nishi on 2022/03/12.
//

import Foundation
import Alamofire

// MARK: - HTTPClientConfiguration -

public final class HTTPClientConfiguration {
    
    /// The configuration used to construct the managed session.
    /// The default value is `.default`.
    ///
    /// - Note: Changes to this value after being passed to an initializer of ``HTTPClient`` will have no effect.
    public lazy var urlSession = URLSessionConfiguration.default
    
    /// A default decoder used to decode JSON in the `HTTPClient.send(_:, decodingCompletion:)` method.
    ///
    /// You can use this property when you want to use a common decoder in your app.
    /// If you want to use a different decoder for each request,
    /// implement the `preferredJSONDecoder` property in the request type that conforms to the ``DecodingRequest`` protocol.
    public lazy var defaultJSONDecoder = JSONDecoder()
    
    /// Creates an ``HTTPClientConfiguration`` instance.
    public init() {}
}

// MARK: - HTTPClient -

public struct HTTPClient {
    
    /*
     * NOTE:
     * This is not `public var` property
     * because changes to the `configuration.urlSession` are not reflected
     * in the `Alamofire.Session.sessionConfiguration`.
     * Its customization is limited to only when initializing `HTTPClient`.
     */
    let configuration: HTTPClientConfiguration
    
    private let session: Session
    
    // MARK: - Initializers
    
    /// Creates an ``HTTPClient`` instance.
    /// - Parameter configuration: A configuration used for HTTP communication.
    public init(configuration: HTTPClientConfiguration = .init()) {
        self.configuration = configuration
        self.session = Session(configuration: configuration.urlSession)
    }
    
    // MARK: - Methods
    
    /// Send a request and receive the simple response.
    /// - Parameters:
    ///   - request: An instance of the request type that conforms to the ``HTTPRequest`` protocol.
    ///   - queue: The queue on which the completion handler is called. The default is `.main`.
    ///   - completion: The handler to be executed once the request has finished.
    public func send(_ request: some HTTPRequest,
                     receiveOn queue: DispatchQueue = .main,
                     completion: @escaping (AFDataResponse<Data?>) -> Void) {
        makeDataRequest(from: request)
            .response(queue: queue, completionHandler: completion)
    }
    
    /// Send a request and receive the simple response asynchronously.
    /// - Parameters:
    ///   - request: An instance of the request type that conforms to the ``HTTPRequest`` protocol.
    /// - Returns: The response.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    @discardableResult
    public func send(_ request: some HTTPRequest) async -> AFDataResponse<Data?> {
        await withCheckedContinuation { continuation in
            send(request, receiveOn: .main, completion: continuation.resume(returning:))
        }
    }
    
    /// Send a request and decode the response JSON.
    /// - Parameters:
    ///   - request: An instance of the request type that conforms to the ``DecodingRequest`` protocol.
    ///   - queue: The queue on which the completion handler is called. The default is `.main`.
    ///   - decodingCompletion: The handler to be executed once the request and decoding has finished.
    public func send<Request: DecodingRequest>(_ request: Request,
                                               receiveOn queue: DispatchQueue = .main,
                                               decodingCompletion: @escaping (AFDataResponse<Request.Response>) -> Void) {
        let decoder = Request.preferredJSONDecoder ?? configuration.defaultJSONDecoder
        makeDataRequest(from: request)
            .responseDecodable(queue: queue, decoder: decoder, completionHandler: decodingCompletion)
    }
    
    /// Send a request asynchronously and decode the response JSON.
    /// - Parameters:
    ///   - request: An instance of the request type that conforms to the ``DecodingRequest`` protocol.
    /// - Returns: The response that contains decoded model from JSON.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func send<Request: DecodingRequest>(_ request: Request) async -> AFDataResponse<Request.Response> {
        await withCheckedContinuation { continuation in
            send(request, receiveOn: .main, decodingCompletion: continuation.resume(returning:))
        }
    }
    
    private func makeDataRequest<Request: HTTPRequest>(from request: Request) -> DataRequest {
        session
            .request(request.urlComponents,
                     method: Request.httpMethod,
                     parameters: (request as? any HTTPBodySendable)?.body,
                     encoding: JSONEncoding.default,
                     headers: request.headers)
            .validate(statusCode: request.acceptableStatusCodes)
            .validate(contentType: request.acceptableContentTypes)
    }
}

@available(*, unavailable, renamed: "HTTPClient")
public struct AFClient {}
