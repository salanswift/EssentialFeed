//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Arsalan Akhtar on 7/24/21.
//

import Foundation

internal final class FeedItemMapper {


    private struct Root: Decodable {
        let items: [Item]
        
        var feed: [FeedItem] {
            return items.map {
                $0.item
            }
        }
    }

    private struct Item : Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            return FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
   internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return try JSONDecoder().decode(Root.self, from: data).items.map{
            $0.item
        }
    }
    
    internal static func map(_ data: Data, response: HTTPURLResponse) -> RemoteFeedLoader.Result {
    
    guard response.statusCode == 200,
   
    let root = try?  JSONDecoder().decode(Root.self, from: data) else {
        return .failure(RemoteFeedLoader.Error.invalidData)
        }
        return .success(root.feed)
    }
}
