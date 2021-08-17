//
//  EssentialFeedAPIEndToEndTest.swift
//  EssentialFeedAPIEndToEndTest
//
//  Created by Arsalan Akhtar on 8/16/21.
//

import XCTest
import EssentialFeed
class EssentialFeedAPIEndToEndTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_endToEndTestServerGETFeedResult_MatchesFixedTestAccountData() {
        let client = URLSessionHTTPClient()
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let loader = RemoteFeedLoader(url: testServerURL, client: client)
        let exp = expectation(description: "wait for load completion")
        var receivedResult: LoadFeedResult?
        loader.load() { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10.0)
            
        switch receivedResult {
        case let .success(item)?:
            XCTAssertEqual(item.count, 8, "Expected 8 items in the test account feed")
        case let .failure(error)?:
            XCTFail("Expected successful feed got \(error) instead")
        default:
            XCTFail("Expected successful feed got no result")
        }
    }

}
