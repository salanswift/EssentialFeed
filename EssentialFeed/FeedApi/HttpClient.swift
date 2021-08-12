//
//  HttpClient.swift
//  EssentialFeed
//
//  Created by Arsalan Akhtar on 7/24/21.
//

import Foundation

public enum HttpClientResult {
    case success(Data,HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url:URL,completion: @escaping (HttpClientResult) -> Void)
}
