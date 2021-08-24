//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Arsalan Akhtar on 7/20/21.
//

import XCTest
import EssentialFeed

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_,client) = makeSUT()
        XCTAssertTrue(client.requestedUrls.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "http://a-given-url.com")!
        let (sut,client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedUrls, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "http://a-given-url.com")!
        let (sut,client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedUrls, [url,url])
    }
    
    func test_deliversErrorOnClientError() {
        let (sut,client) = makeSUT()
        
        expect(sut, toCompleteWith: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_deliversErrorOnNon200HttpResponse() {
       let (sut,client) = makeSUT()
       let samples = [199, 201, 300, 400, 500]
       samples.enumerated().forEach { index, code in
        expect(sut, toCompleteWith: failure(.invalidData), when: {
            let json = makeItemJSON([])
            client.complete(withStatusCode: code, data: json, at: index)
        })
       }
    }
    
    func test_load_deliverErrorsOn200HttpResponseWithInvalidJSON(){
        let (sut, client) = makeSUT()
      
        expect(sut, toCompleteWith: failure(.invalidData), when: {
                let invalidJSON = Data("Invalid JSON".utf8)
                client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliverErrorsOn200HttpResponseWithEmptyJSONList(){
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: RemoteFeedLoader.Result.success([]), when: {
            let emptyListJSON = makeItemJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    func test_load_deliverErrorsOn200HttpResponseWithEJSONItems(){
        let (sut, client) = makeSUT()
       
        let item1 = makeItem(id: UUID(),
            imageURL: URL(string: "http://a-url.com")!)
        
        
        let item2 = makeItem(
            id: UUID(),
            description: "a description",
            location: "a location",
            imageURL: URL(string: "http://another-url.com")!)
        
      
        
        expect(sut, toCompleteWith: .success([item1.model,item2.model]), when: {
            let json = makeItemJSON([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        })
    }
    
    func test_load_DoesNotDeliverAfterSUTInstanceHasBeenDeallocated() {
        
        let url = URL(string: "http://a-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        var capturedResult = [RemoteFeedLoader.Result]()
        sut?.load {
            capturedResult.append($0)
        }
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemJSON([]))
        XCTAssertTrue(capturedResult.isEmpty)
    }
    
//
    //Mark: Helpers
    private func makeSUT(url:URL = URL(string: "http://a-given-url.com")!, file: StaticString = #file, line: UInt = #line) -> (sut:RemoteFeedLoader, client:HTTPClientSpy) {
        
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        self.trackForMemoryLeak(client, file: file, line: line)
        self.trackForMemoryLeak(sut, file: file, line: line)
        
        return (sut, client)
    }
    
    
   
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model:FeedItem, json: [String: Any]) {
        
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { (acc, e) in
            if let value = e.value { acc[e.key] =  value}
        }
        
        return(item,json)
    }
    
    private func makeItemJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        let exp = expectation(description: "wait for load completion")
        
        sut.load() { receivedResult in
            
            switch(receivedResult, expectedResult) {
            case let (.success(receivedItems), .success(expectedItems)):
                XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            default:
                XCTFail("Expected Result \(expectedResult), got \(receivedResult)", file: file, line: line)
            }
             
            exp.fulfill()
        }
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    private class HTTPClientSpy: HTTPClient {
       
    var requestedUrls: [URL] {
            return messages.map {
                $0.url
            }
        }
    
    private var messages = [(url: URL, completion: (HttpClientResult) -> Void)]()
        
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
            messages.append((url: url, completion: completion))
        }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }

    func complete(withStatusCode code: Int, data: Data, at index:Int = 0) {
            let response = HTTPURLResponse(url: requestedUrls[index], statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
                
            messages[index].completion(.success(data, response))
        }
    }
}
