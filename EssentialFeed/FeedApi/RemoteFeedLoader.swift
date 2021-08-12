//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Arsalan Akhtar on 7/20/21.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    
   private let client: HTTPClient
   private let url: URL
   
    public enum Error : Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
    
    
   public init(url:URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    
    public func load(completion: @escaping (LoadFeedResult) -> Void) {
        
        client.get(from: url) { [weak self] httpClientResult in
            
            guard self != nil else {
                return
            }
            
            switch httpClientResult {
                
                case let .success(data, response):
                    
                    completion(FeedItemMapper.map(data, response: response))
                    
                case .failure:
                    completion(.failure(Error.connectivity))
            }
        }
    }
}


