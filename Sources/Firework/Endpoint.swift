//
//  Endpoint.swift
//  
//
//  Created by Yusaku Nishi on 2020/10/23.
//

/// An API endpoint representation.
public struct Endpoint: Hashable {
    
    public let urlString: String
    
    public init(_ urlString: String) {
        self.urlString = urlString
    }
    
    @inlinable
    public static func / (base: Endpoint, additionalPath: String) -> Endpoint {
        return Endpoint(base.urlString + "/" + additionalPath)
    }
}

// MARK: - ExpressibleByStringLiteral

extension Endpoint: ExpressibleByStringLiteral {
    
    public init(stringLiteral: String) {
        self.init(stringLiteral)
    }
}
