//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Arsalan Akhtar on 8/10/21.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    struct UnexpectedValueRepresentationError: Error { }
    
    func get(from url: URL, completion: @escaping (HttpClientResult) -> Void) {
        //let url = URL(string: "http://wrongurl.com")!
        session.dataTask(with: url){_,_,error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValueRepresentationError()))
            }
        }.resume()
    }
    
}

class URLSessionHTTPClientTests: XCTestCase {
    
    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequest()
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequest()
    }
    
    func test_getFromURL_performGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "wait for request")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failOnRequestError() {
        let requestError = NSError(domain: "any error", code: 1)
        let receivedError = resultErrorFor(data: nil, response:nil, error: requestError) as NSError?
        XCTAssertEqual(receivedError?.code, requestError.code)
        XCTAssertEqual(receivedError?.domain, requestError.domain)
   
    }
    
    func test_getFromURL_failsOnALLInvalidRepresentationCases() {
        
        let nonHTTPURLResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        
        let anyHTTPURLResponse = HTTPURLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName:nil)
        
        let anyData = Data(bytes: "Any data".utf8)
        
        let anyError = NSError(domain: "any error", code: 1)
        
        XCTAssertNotNil(resultErrorFor(data: nil, response:nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response:nonHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response:anyHTTPURLResponse, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response:nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData, response:nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response:nil, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response:anyHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: nil, response:nonHTTPURLResponse, error: anyError))
        XCTAssertNotNil(resultErrorFor(data: anyData, response:nonHTTPURLResponse, error: nil))
    }
    
    // Mark: - Helpers
    
    private func anyURL() -> URL {
        return URL(string: "http://anyurl.com")!
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: NSError?,file: StaticString = #file, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file:file, line: line)
        var receivedError: Error?
        let exp = expectation(description: "wait for completion")
        sut.get(from: anyURL()){result in
            switch result {
            case let .failure(error):
                receivedError = error
               break
                
            default:
                XCTFail("Expected failure, got result \(result) instead",file: file, line:line)
                
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        
        return receivedError
    }
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    private class URLProtocolStub: URLProtocol {
       
        var receivedURLs = [URL]()
        static var requestObserver: ((URLRequest) -> Void)?
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        private static var stub: Stub?
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            
            requestObserver = observer
            
        }
        
        static func stub(data: Data?, response: URLResponse?, error: NSError?) {
            stub = Stub(data: data, response: response, error: error)
        }
    
        static func startInterceptingRequest() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        static func stopInterceptingRequest() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
        
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
    

}
