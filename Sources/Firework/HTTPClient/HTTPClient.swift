//
//  HTTPClient.swift
//  
//
//  Created by Yusaku Nishi on 2022/03/12.
//

import Foundation

// MARK: - HTTPClientConfiguration -

public final class HTTPClientConfiguration {
    
    /// The shared configuration.
    public static let shared = HTTPClientConfiguration()
    
    /// The configuration used to construct the managed session.
    /// The default value is `.default`.
    public lazy var urlSession = URLSessionConfiguration.default
    
    /// A default decoder used to decode JSON in the `HTTPClient.send(_:, decodingCompletion:)` method.
    ///
    /// You can use this property when you want to use a common decoder in your app.
    /// If you want to use a different decoder for each request,
    /// implement the `preferredJSONDecoder` property in the request type that conforms to the ``DecodingRequest`` protocol.
    public lazy var defaultJSONDecoder = JSONDecoder()
}

// MARK: - HTTPClient -

public struct HTTPClient<Adaptor: HTTPClientAdaptor> {
    
    public var configuration = HTTPClientConfiguration.shared
    @usableFromInline let adaptor: Adaptor
    
    /// Send a request and receive the simple response.
    /// - Parameters:
    ///   - request: An instance of the request type that conforms to the ``HTTPRequest`` protocol.
    ///   - queue: The queue on which the completion handler is called. The default is `.main`.
    ///   - completion: The handler to be executed once the request has finished.
    @inlinable
    public func send<Request: HTTPRequest>(_ request: Request,
                                          receiveOn queue: DispatchQueue = .main,
                                          completion: @escaping (Result<Data?, Adaptor.Failure>) -> Void) {
        adaptor.send(request, receiveOn: queue, completion: completion)
    }
    
    /// Send a request and receive the simple response asynchronously.
    /// - Parameters:
    ///   - request: An instance of the request type that conforms to the ``HTTPRequest`` protocol.
    /// - Returns: The response data.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    @discardableResult
    public func send<Request: HTTPRequest>(_ request: Request) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            adaptor.send(request, receiveOn: .main, completion: continuation.resume(with:))
        }
    }
    
    /// Send a request and decode the response JSON.
    /// - Parameters:
    ///   - request: An instance of the request type that conforms to the ``DecodingRequest`` protocol.
    ///   - queue: The queue on which the completion handler is called. The default is `.main`.
    ///   - decodingCompletion: The handler to be executed once the request and decoding has finished.
    public func send<Request: DecodingRequest>(_ request: Request,
                                               receiveOn queue: DispatchQueue = .main,
                                               decodingCompletion: @escaping (Result<Request.Response, any Error>) -> Void) {
        adaptor.send(request, receiveOn: queue) { (result: Result<Data, Adaptor.Failure>) in
            decodingCompletion(Result {
                let decoder = Request.preferredJSONDecoder ?? configuration.defaultJSONDecoder
                return try decoder.decode(Request.Response.self, from: result.get())
            })
        }
    }
    
    /// Send a request asynchronously and decode the response JSON.
    /// - Parameters:
    ///   - request: An instance of the request type that conforms to the ``DecodingRequest`` protocol.
    /// - Returns: The decoded response model from JSON.
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func send<Request: DecodingRequest>(_ request: Request) async throws -> Request.Response {
        try await withCheckedThrowingContinuation { continuation in
            send(request, receiveOn: .main, decodingCompletion: continuation.resume(with:))
        }
    }
}
