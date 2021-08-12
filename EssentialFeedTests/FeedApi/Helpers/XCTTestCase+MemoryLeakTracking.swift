//
//  XCTTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Arsalan Akhtar on 7/30/21.
//

import XCTest

extension XCTestCase {
     func trackForMemoryLeak(_ instance: AnyObject,  file: StaticString, line: UInt) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
    
}
