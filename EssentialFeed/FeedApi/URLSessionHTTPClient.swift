//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Arsalan Akhtar on 7/31/21.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValueRepresentationError: Error { }
    
    public func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
        //let url = URL(string: "http://wrongurl.com")!
        session.dataTask(with: url){data,response,error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedValueRepresentationError()))
            }
        }.resume()
    }
    
}
