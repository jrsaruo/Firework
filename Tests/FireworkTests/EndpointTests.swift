//
//  EndpointTests.swift
//  
//
//  Created by Yusaku Nishi on 2021/04/19.
//

import XCTest
@testable import Firework

final class EndpointTests: XCTestCase {
    
    func testEquatable() {
        XCTAssertEqual(Endpoint("https://www.sample.com"), Endpoint("https://www.sample.com"))
        XCTAssertNotEqual(Endpoint("https://www.sample.com"), Endpoint("https://www.sample.com/"))
        XCTAssertNotEqual(Endpoint("https://www.sample.com"), Endpoint("https://sample.com"))
    }
    
    func testExpressionByStringLiteral() {
        let endpoint = Endpoint("https://www.sample.com")
        let endpointByStringLiteral: Endpoint = "https://www.sample.com"
        XCTAssertEqual(endpoint, endpointByStringLiteral)
    }
    
    func testURLString() {
        let endpoint = Endpoint("https://www.sample.com")
        XCTAssertEqual(endpoint.urlString, "https://www.sample.com")
    }
    
    func testJoiningOperator() {
        let endpoint = Endpoint("https://www.sample.com") / "some" / "api"
        XCTAssertEqual(endpoint, Endpoint("https://www.sample.com/some/api"))
    }
}
