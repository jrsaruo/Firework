//
//  HTTPClientTests.swift
//  
//
//  Created by Yusaku Nishi on 2021/11/08.
//

import XCTest
@testable import Firework

final class HTTPClientTests: XCTestCase {
    
    final class StubAdaptor: HTTPClientAdaptor {
        
        var result: Result<Data, Error>
        private(set) var calledCount = 0
        
        init(result: Result<Data, Error>) {
            self.result = result
        }
        
        func send<Request: APIRequest>(_ request: Request,
                                       receiveOn queue: DispatchQueue = .main,
                                       completion: @escaping (Result<Data, Error>) -> Void) {
            calledCount += 1
            queue.async { [unowned self] in
                completion(result)
            }
        }
    }
    
    private struct Sample: Decodable {
        let someProperty: String
    }
    
    private struct SampleError: Error {}
    
    func testSendingGETRequest() {
        struct SampleGETRequest: GETRequest {
            var endpoint: Endpoint { "https://dummy.api/sample" }
        }
        
        XCTContext.runActivity(named: "Success") { _ in
            let httpClient = HTTPClient(adaptor: StubAdaptor(result: .success(Data("dummy".utf8))))
            assert(httpClient.adaptor.calledCount == 0)
            
            let expectation = expectation(description: "HTTP communication success")
            httpClient.send(SampleGETRequest()) { result in
                defer { expectation.fulfill() }
                switch result {
                case .success(let data?):
                    XCTAssertEqual(String(decoding: data, as: UTF8.self), "dummy")
                case .success(nil):
                    XCTFail("data should not be nil.")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
            wait(for: [expectation], timeout: 0.2)
            XCTAssertEqual(httpClient.adaptor.calledCount, 1)
        }
        
        XCTContext.runActivity(named: "Failure") { _ in
            let httpClient = HTTPClient(adaptor: StubAdaptor(result: .failure(SampleError())))
            assert(httpClient.adaptor.calledCount == 0)
            
            let expectation = expectation(description: "HTTP communication failure")
            httpClient.send(SampleGETRequest()) { result in
                defer { expectation.fulfill() }
                switch result {
                case .success:
                    XCTFail("The request should fail.")
                case .failure(let error):
                    XCTAssert(error is SampleError)
                }
            }
            wait(for: [expectation], timeout: 0.2)
            XCTAssertEqual(httpClient.adaptor.calledCount, 1)
        }
    }
    
    func testSendingAndDecoding() {
        struct Request: GETRequest, DecodingRequest {
            typealias Response = Sample
            var endpoint: Endpoint { "https://dummy.api/sample" }
        }
        
        struct RequestUsingPreferredJSONDecoder: GETRequest, DecodingRequest {
            typealias Response = Sample
            var endpoint: Endpoint { "https://dummy.api/sample" }
            
            static let preferredJSONDecoder: JSONDecoder? = {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return decoder
            }()
        }
        
        enum RequestType {
            case defaultJSONDecoder, preferredJSONDecoder
        }
        
        let camelCaseJSON = """
        { "someProperty": "some property" }
        """
        
        let snakeCaseJSON = """
        { "some_property": "some property" }
        """
        
        XCTContext.runActivity(named: "with shared configuration") { _ in
            XCTContext.runActivity(named: "If preferredJSONDecoder is nil, defaultJSONDecoder will be used.") { _ in
                let httpClient = HTTPClient(adaptor: StubAdaptor(result: .success(Data(camelCaseJSON.utf8))))
                assert(httpClient.adaptor.calledCount == 0)
                
                let expectation = expectation(description: "HTTP communication success")
                httpClient.send(Request(), decodingCompletion: { result in
                    defer { expectation.fulfill() }
                    switch result {
                    case .success(let sample):
                        XCTAssertEqual(sample.someProperty, "some property")
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                })
                wait(for: [expectation], timeout: 0.2)
                XCTAssertEqual(httpClient.adaptor.calledCount, 1)
            }
            XCTContext.runActivity(named: "If non-nil preferredJSONDecoder exists, it will be used.") { _ in
                let httpClient = HTTPClient(adaptor: StubAdaptor(result: .success(Data(snakeCaseJSON.utf8))))
                let expectation = expectation(description: "HTTP communication success")
                httpClient.send(RequestUsingPreferredJSONDecoder(), decodingCompletion: { result in
                    defer { expectation.fulfill() }
                    switch result {
                    case .success(let sample):
                        XCTAssertEqual(sample.someProperty, "some property")
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                })
                wait(for: [expectation], timeout: 0.2)
            }
        }
        
        XCTContext.runActivity(named: "with custom configuration") { _ in
            XCTContext.runActivity(named: "If preferredJSONDecoder is nil, defaultJSONDecoder will be used.") { _ in
                let customConfiguration = HTTPClientConfiguration()
                customConfiguration.defaultJSONDecoder.keyDecodingStrategy = .convertFromSnakeCase
                var httpClient = HTTPClient(adaptor: StubAdaptor(result: .success(Data(snakeCaseJSON.utf8))))
                httpClient.configuration = customConfiguration
                
                let expectation = expectation(description: "HTTP communication success")
                httpClient.send(Request(), decodingCompletion: { result in
                    defer { expectation.fulfill() }
                    switch result {
                    case .success(let sample):
                        XCTAssertEqual(sample.someProperty, "some property")
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                })
                wait(for: [expectation], timeout: 0.2)
            }
            XCTContext.runActivity(named: "If non-nil preferredJSONDecoder exists, it will be used.") { _ in
                let customConfiguration = HTTPClientConfiguration()
                customConfiguration.defaultJSONDecoder.keyDecodingStrategy = .useDefaultKeys
                var httpClient = HTTPClient(adaptor: StubAdaptor(result: .success(Data(snakeCaseJSON.utf8))))
                httpClient.configuration = customConfiguration
                
                let expectation = expectation(description: "HTTP communication success")
                httpClient.send(RequestUsingPreferredJSONDecoder(), decodingCompletion: { result in
                    defer { expectation.fulfill() }
                    switch result {
                    case .success(let sample):
                        XCTAssertEqual(sample.someProperty, "some property")
                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                    }
                })
                wait(for: [expectation], timeout: 0.2)
            }
        }
        
        XCTContext.runActivity(named: "The decoding failure") { _ in
            let invalidJSON = """
            { "id": 10 }
            """
            let httpClient = HTTPClient(adaptor: StubAdaptor(result: .success(Data(invalidJSON.utf8))))
            let expectation = expectation(description: "HTTP communication success")
            httpClient.send(Request(), decodingCompletion: { result in
                defer { expectation.fulfill() }
                switch result {
                case .success:
                    XCTFail("The decoding should fail.")
                case .failure(DecodingError.keyNotFound(let codingKey, _)):
                    XCTAssertEqual(codingKey.stringValue, "someProperty")
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            })
            wait(for: [expectation], timeout: 0.2)
        }
        
        XCTContext.runActivity(named: "The request failure") { _ in
            let httpClient = HTTPClient(adaptor: StubAdaptor(result: .failure(SampleError())))
            assert(httpClient.adaptor.calledCount == 0)
            
            let expectation = expectation(description: "HTTP communication failure")
            httpClient.send(Request(), decodingCompletion: { result in
                defer { expectation.fulfill() }
                switch result {
                case .success:
                    XCTFail("The request should fail.")
                case .failure(let error):
                    XCTAssert(error is SampleError)
                }
            })
            wait(for: [expectation], timeout: 0.2)
            XCTAssertEqual(httpClient.adaptor.calledCount, 1)
        }
    }
}
