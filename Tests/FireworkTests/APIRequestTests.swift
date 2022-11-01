//
//  APIRequestTests.swift
//  
//
//  Created by Yusaku Nishi on 2021/04/19.
//

import XCTest
@testable import Firework

final class APIRequestTests: XCTestCase {
    
    func testGETRequestProperties() {
        struct TestGETRequest: GETRequest {
            var endpoint: Endpoint { "https://www.sample.com" }
        }
        
        XCTAssertEqual(TestGETRequest.httpMethod, .get)
        
        let request = TestGETRequest()
        XCTAssertNil(request.headers)
        XCTAssertEqual(request.acceptableStatusCodes, 200..<400)
        
        let urlComponents = request.urlComponents
        XCTAssertEqual(urlComponents.url, URL(string: "https://www.sample.com")!)
        XCTAssertNil(urlComponents.queryItems)
    }
    
    func testPOSTRequestProperties() {
        struct TestPOSTRequest: POSTRequest {
            var endpoint: Endpoint { "https://www.sample.com" }
            var body: [String: Any] = ["some": "data"]
        }
        
        XCTAssertEqual(TestPOSTRequest.httpMethod, .post)
        
        let request = TestPOSTRequest()
        XCTAssertNil(request.headers)
        XCTAssertEqual(request.acceptableStatusCodes, 200..<400)
        
        let urlComponents = request.urlComponents
        XCTAssertEqual(urlComponents.url, URL(string: "https://www.sample.com")!)
        XCTAssertNil(urlComponents.queryItems)
    }
    
    func testPUTRequestProperties() {
        struct TestPUTRequest: PUTRequest {
            var endpoint: Endpoint { "https://www.sample.com" }
            var body: [String: Any] = ["some": "data"]
        }
        
        XCTAssertEqual(TestPUTRequest.httpMethod, .put)
        
        let request = TestPUTRequest()
        XCTAssertNil(request.headers)
        XCTAssertEqual(request.acceptableStatusCodes, 200..<400)
        
        let urlComponents = request.urlComponents
        XCTAssertEqual(urlComponents.url, URL(string: "https://www.sample.com")!)
        XCTAssertNil(urlComponents.queryItems)
    }
    
    func testPATCHRequestProperties() {
        struct TestPATCHRequest: PATCHRequest {
            var endpoint: Endpoint { "https://www.sample.com" }
            var body: [String: Any] = ["some": "data"]
        }
        
        XCTAssertEqual(TestPATCHRequest.httpMethod, .patch)
        
        let request = TestPATCHRequest()
        XCTAssertNil(request.headers)
        XCTAssertEqual(request.acceptableStatusCodes, 200..<400)
        
        let urlComponents = request.urlComponents
        XCTAssertEqual(urlComponents.url, URL(string: "https://www.sample.com")!)
        XCTAssertNil(urlComponents.queryItems)
    }
    
    func testDELETERequestProperties() {
        struct TestDELETERequest: DELETERequest {
            var endpoint: Endpoint { "https://www.sample.com" }
        }
        
        XCTAssertEqual(TestDELETERequest.httpMethod, .delete)
        
        let request = TestDELETERequest()
        XCTAssertNil(request.headers)
        XCTAssertEqual(request.acceptableStatusCodes, 200..<400)
        
        let urlComponents = request.urlComponents
        XCTAssertEqual(urlComponents.url, URL(string: "https://www.sample.com")!)
        XCTAssertNil(urlComponents.queryItems)
    }
    
    func testURLComponentsWithQueries() {
        struct TestRequest: GETRequest {
            var endpoint: Endpoint { "https://www.sample.com" }
            var queryItems: [URLQueryItem]? { [URLQueryItem(name: "some-query", value: "value")] }
        }
        
        let urlComponents = TestRequest().urlComponents
        XCTAssertEqual(urlComponents.url, URL(string: "https://www.sample.com?some-query=value")!)
    }
}
