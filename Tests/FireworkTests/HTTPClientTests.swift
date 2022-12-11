//
//  HTTPClientTests.swift
//  
//
//  Created by Yusaku Nishi on 2021/11/08.
//

import XCTest
import Alamofire
@testable import Firework

final class HTTPClientTests: XCTestCase {
    
    final class MockURLProtocol: URLProtocol {
        
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))!
        
        override static func canInit(with task: URLSessionTask) -> Bool {
            true
        }
        
        override static func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            do {
                let (response, data) = try Self.requestHandler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        override func stopLoading() {
            // NOP
        }
    }
    
    private var client: AFClient!
    
    override func setUp() {
        super.setUp()
        
        MockURLProtocol.requestHandler = { _ in
            fatalError("`MockURLProtocol.requestHandler` must be initialized before tests.")
        }
        
        let configuration = HTTPClientConfiguration()
        configuration.urlSession = .ephemeral
        configuration.urlSession.protocolClasses = [MockURLProtocol.self]
        client = AFClient(configuration: configuration)
    }
    
    // MARK: - Sending request tests
    
    private struct SampleGETRequest: GETRequest {
        var endpoint: Endpoint { "https://dummy.api/sample" }
    }
    
    func testSendingGETRequest() {
        XCTContext.runActivity(named: "Success") { _ in
            // Arrange
            MockURLProtocol.requestHandler = { request in
                XCTAssertEqual(request.url, URL(string: "https://dummy.api/sample")!)
                XCTAssertEqual(request.httpMethod, "GET")
                return (HTTPURLResponse(), Data("dummy".utf8))
            }
            
            // Act
            let expectation = expectation(description: "HTTP communication success")
            client.send(SampleGETRequest()) { response in
                defer { expectation.fulfill() }
                switch response.result {
                case .success(let data?):
                    XCTAssertEqual(String(decoding: data, as: UTF8.self), "dummy")
                case .success(nil):
                    XCTFail("data should not be nil.")
                case .failure(let error):
                    XCTFail("Unexpected error: \(error)")
                }
            }
            wait(for: [expectation], timeout: 0.2)
        }
        
        XCTContext.runActivity(named: "Failure") { _ in
            // Arrange
            MockURLProtocol.requestHandler = { request in
                (HTTPURLResponse(url: try XCTUnwrap(request.url),
                                 statusCode: 404,
                                 httpVersion: nil,
                                 headerFields: nil)!,
                 Data())
            }
            
            // Act
            let expectation = expectation(description: "HTTP communication failure")
            client.send(SampleGETRequest()) { response in
                defer { expectation.fulfill() }
                switch response.result {
                case .success:
                    XCTFail("The request should fail.")
                case .failure(let error):
                    XCTAssertEqual(error.responseCode, 404)
                }
            }
            wait(for: [expectation], timeout: 0.2)
        }
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testSendingGETRequestAsync_success() async throws {
        // Arrange
        MockURLProtocol.requestHandler = { _ in
            (HTTPURLResponse(), Data("dummy".utf8))
        }
        
        // Act
        let response = await client.send(SampleGETRequest())
        
        // Assert
        let data = try XCTUnwrap(response.result.get())
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "dummy")
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testSendingGETRequestAsync_failure() async throws {
        // Arrange
        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: try XCTUnwrap(request.url),
                             statusCode: 404,
                             httpVersion: nil,
                             headerFields: nil)!,
             Data())
        }
        
        // Act
        let response = await client.send(SampleGETRequest())
        
        // Assert
        XCTAssertThrowsError(try response.result.get())
        let error = try XCTUnwrap(response.error)
        XCTAssertEqual(error.responseCode, 404)
    }
    
    // MARK: - Decoding tests
    
    private struct SampleResponse: Decodable {
        let someProperty: String
    }
    
    private struct SampleDecodingRequest: GETRequest, DecodingRequest {
        typealias Response = SampleResponse
        var endpoint: Endpoint { "https://dummy.api/sample/camel-case" }
    }
    
    private struct SampleDecodingRequestPreferringSnakeCase: GETRequest, DecodingRequest {
        typealias Response = SampleResponse
        var endpoint: Endpoint { "https://dummy.api/sample/snake-case" }
        
        static let preferredJSONDecoder: JSONDecoder? = {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return decoder
        }()
    }
    
    private var camelCaseJSON: String {
        #"{ "someProperty": "some property" }"#
    }
    
    private var snakeCaseJSON: String {
        #"{ "some_property": "some property" }"#
    }
    
    private var invalidKeyJSON: String {
        #"{ "id": 10 }"#
    }
    
    func testSendingAndDecoding() {
        XCTContext.runActivity(named: "With default configuration") { _ in
            XCTContext.runActivity(named: "If preferredJSONDecoder is nil, defaultJSONDecoder will be used.") { _ in
                // Arrange
                MockURLProtocol.requestHandler = { [unowned self] _ in
                    (HTTPURLResponse(), Data(camelCaseJSON.utf8))
                }
                
                // Act
                let expectation = expectation(description: "HTTP communication success")
                client.send(SampleDecodingRequest(), decodingCompletion: { response in
                    defer { expectation.fulfill() }
                    switch response.result {
                    case .success(let sample):
                        XCTAssertEqual(sample.someProperty, "some property")
                    case .failure(let error):
                        XCTFail("Unexpected error: \(error)")
                    }
                })
                wait(for: [expectation], timeout: 0.2)
            }
            XCTContext.runActivity(named: "If non-nil preferredJSONDecoder exists, it will be used.") { _ in
                // Arrange
                MockURLProtocol.requestHandler = { [unowned self] _ in
                    (HTTPURLResponse(), Data(snakeCaseJSON.utf8))
                }
                
                // Act
                let expectation = expectation(description: "HTTP communication success")
                client.send(SampleDecodingRequestPreferringSnakeCase(), decodingCompletion: { response in
                    defer { expectation.fulfill() }
                    switch response.result {
                    case .success(let sample):
                        XCTAssertEqual(sample.someProperty, "some property")
                    case .failure(let error):
                        XCTFail("Unexpected error: \(error)")
                    }
                })
                wait(for: [expectation], timeout: 0.2)
            }
        }
        
        XCTContext.runActivity(named: "With custom configuration") { _ in
            let customConfiguration = HTTPClientConfiguration()
            customConfiguration.urlSession = .ephemeral
            customConfiguration.urlSession.protocolClasses = [MockURLProtocol.self]
            XCTContext.runActivity(named: "If preferredJSONDecoder is nil, defaultJSONDecoder will be used.") { _ in
                // Arrange
                customConfiguration.defaultJSONDecoder.keyDecodingStrategy = .convertFromSnakeCase
                let client = AFClient(configuration: customConfiguration)
                
                MockURLProtocol.requestHandler = { [unowned self] _ in
                    (HTTPURLResponse(), Data(snakeCaseJSON.utf8))
                }
                
                // Act
                let expectation = expectation(description: "HTTP communication success")
                client.send(SampleDecodingRequest(), decodingCompletion: { response in
                    defer { expectation.fulfill() }
                    switch response.result {
                    case .success(let sample):
                        XCTAssertEqual(sample.someProperty, "some property")
                    case .failure(let error):
                        XCTFail("Unexpected error: \(error)")
                    }
                })
                wait(for: [expectation], timeout: 0.2)
            }
            XCTContext.runActivity(named: "If non-nil preferredJSONDecoder exists, it will be used.") { _ in
                // Arrange
                customConfiguration.defaultJSONDecoder.keyDecodingStrategy = .useDefaultKeys
                let client = AFClient(configuration: customConfiguration)
                
                MockURLProtocol.requestHandler = { [unowned self] _ in
                    (HTTPURLResponse(), Data(snakeCaseJSON.utf8))
                }
                
                // Act
                let expectation = expectation(description: "HTTP communication success")
                client.send(SampleDecodingRequestPreferringSnakeCase(), decodingCompletion: { response in
                    defer { expectation.fulfill() }
                    switch response.result {
                    case .success(let sample):
                        XCTAssertEqual(sample.someProperty, "some property")
                    case .failure(let error):
                        XCTFail("Unexpected error: \(error)")
                    }
                })
                wait(for: [expectation], timeout: 0.2)
            }
        }
        
        XCTContext.runActivity(named: "The decoding failure") { _ in
            // Arrange
            MockURLProtocol.requestHandler = { [unowned self] _ in
                (HTTPURLResponse(), Data(invalidKeyJSON.utf8))
            }
            
            // Act
            let expectation = expectation(description: "HTTP communication success")
            client.send(SampleDecodingRequest(), decodingCompletion: { response in
                defer { expectation.fulfill() }
                switch response.result {
                case .success:
                    XCTFail("The decoding should fail.")
                case .failure(.responseSerializationFailed(
                    reason: .decodingFailed(DecodingError.keyNotFound(let codingKey, _))
                )):
                    XCTAssertEqual(codingKey.stringValue, "someProperty")
                case .failure(let error):
                    XCTFail("Unexpected error: \(error)")
                }
            })
            wait(for: [expectation], timeout: 0.2)
        }
        
        XCTContext.runActivity(named: "The request failure") { _ in
            // Arrange
            MockURLProtocol.requestHandler = { request in
                (HTTPURLResponse(url: try XCTUnwrap(request.url),
                                 statusCode: 404,
                                 httpVersion: nil,
                                 headerFields: nil)!,
                 Data())
            }
            
            // Act
            let expectation = expectation(description: "HTTP communication failure")
            client.send(SampleDecodingRequest(), decodingCompletion: { response in
                defer { expectation.fulfill() }
                switch response.result {
                case .success:
                    XCTFail("The request should fail.")
                case .failure(let error):
                    XCTAssertEqual(error.responseCode, 404)
                }
            })
            wait(for: [expectation], timeout: 0.2)
        }
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testSendingAndDecodingAsync_success() async throws {
        // Arrange
        MockURLProtocol.requestHandler = { [unowned self] _ in
            (HTTPURLResponse(), Data(camelCaseJSON.utf8))
        }
        
        // Act
        let response = await client.send(SampleDecodingRequest())
        
        // Assert
        let sample = try response.result.get()
        XCTAssertEqual(sample.someProperty, "some property")
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testSendingAndDecodingAsync_decodingFailure() async throws {
        // Arrange
        MockURLProtocol.requestHandler = { [unowned self] _ in
            (HTTPURLResponse(), Data(invalidKeyJSON.utf8))
        }
        
        // Act
        let response = await client.send(SampleDecodingRequest())
        
        // Assert
        XCTAssertThrowsError(try response.result.get())
        let error = try XCTUnwrap(response.error)
        guard case .responseSerializationFailed(reason: .decodingFailed(DecodingError.keyNotFound(let codingKey, _))) = error else {
            throw error
        }
        XCTAssertEqual(codingKey.stringValue, "someProperty")
    }
    
    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
    func testSendingAndDecodingAsync_requestFailure() async throws {
        // Arrange
        MockURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: try XCTUnwrap(request.url),
                             statusCode: 404,
                             httpVersion: nil,
                             headerFields: nil)!,
             Data())
        }
        
        // Act
        let response = await client.send(SampleDecodingRequest())
        
        // Assert
        XCTAssertThrowsError(try response.result.get())
        let error = try XCTUnwrap(response.error)
        XCTAssertEqual(error.responseCode, 404)
    }
}
