//
//  HTTPClient.swift
//  
//
//  Created by Yusaku Nishi on 2022/03/12.
//

import Foundation

// MARK: - HTTPClientConfiguration -

public final class HTTPClientConfiguration {
    
    public static let shared = HTTPClientConfiguration()
    
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
    ///   - request: An instance of the request type that conforms to the ``APIRequest`` protocol.
    ///   - queue: The queue on which the completion handler is called. The default is `.main`.
    ///   - completion: The handler to be executed once the request has finished.
    @inlinable
    public func send<Request: APIRequest>(_ request: Request,
                                          receiveOn queue: DispatchQueue = .main,
                                          completion: @escaping (Result<Data?, Adaptor.Failure>) -> Void) {
        adaptor.send(request, receiveOn: queue, completion: completion)
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func send<Request: APIRequest>(_ request: Request) async throws -> Data? {
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
                                               decodingCompletion: @escaping (Result<Request.Response, Error>) -> Void) {
        adaptor.send(request, receiveOn: queue, completion: { (result: Result<Data, Adaptor.Failure>) in
            let finalResult: Result<Request.Response, Error>
            defer { decodingCompletion(finalResult) }
            
            switch result {
            case .success(let data):
                do {
                    let decoder = Request.preferredJSONDecoder ?? configuration.defaultJSONDecoder
                    let decoded = try decoder.decode(Request.Response.self, from: data)
                    finalResult = .success(decoded)
                } catch {
                    finalResult = .failure(error)
                }
            case .failure(let error):
                finalResult = .failure(error)
            }
        })
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    public func send<Request: DecodingRequest>(_ request: Request) async throws -> Request.Response {
        try await withCheckedThrowingContinuation { continuation in
            send(request, decodingCompletion: continuation.resume(with:))
        }
    }
}
