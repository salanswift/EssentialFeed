//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Arsalan Akhtar on 7/18/21.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
