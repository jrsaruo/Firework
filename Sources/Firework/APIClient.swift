//
//  APIClient.swift
//  
//
//  Created by Yusaku Nishi on 2020/10/23.
//

import Alamofire

public struct APIClient {
    
    private init() {}
    
    public static func send<Request: APIRequest>(_ request: Request,
                                                 completion: @escaping (Result<Void, Error>) -> Void) {
        request.alamofireRequest.response { response in
            let result: Result<Void, Error>
            defer { completion(result) }
            
            switch response.result {
            case .success:
                result = .success(())
            case .failure(let error):
                result = .failure(error)
            }
        }
    }
}

extension APIRequest {
    
    var alamofireRequest: DataRequest {
        AF.request(urlComponents,
                   method: Self.httpMethod,
                   parameters: (self as? Postable)?.body,
                   encoding: JSONEncoding.default,
                   headers: headers)
            .validate(statusCode: acceptableStatusCodes)
    }
}
