//
//  HTTPClientAdaptor.swift
//  
//
//  Created by Yusaku Nishi on 2022/03/12.
//

import Foundation

public protocol HTTPClientAdaptor {
    associatedtype Failure: Error
    
    func send(_ request: some HTTPRequest,
              receiveOn queue: DispatchQueue,
              completion: @escaping (Result<Data?, Failure>) -> Void)
    
    func send(_ request: some HTTPRequest,
              receiveOn queue: DispatchQueue,
              completion: @escaping (Result<Data, Failure>) -> Void)
}

public extension HTTPClientAdaptor {
    
    func send(_ request: some HTTPRequest,
              receiveOn queue: DispatchQueue,
              completion: @escaping (Result<Data?, Failure>) -> Void) {
        send(request, receiveOn: queue) { (result: Result<Data, Failure>) in
            completion(result.map { $0 as Data? })
        }
    }
}
