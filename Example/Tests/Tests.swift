import UIKit
import XCTest
import RxSwift
import RxPager

// MARK: structs

/// Sample Page Data Struct
struct Page {
  let values: [Int]
  let hasNext: Bool
}

// MARK: globals

/// page factory helper
func getPager() -> Pager<Page> {
  return Pager(
    paging: { (previousPage: Page?) -> Observable<Page> in
      let last = previousPage?.values.last ?? 0
      return Observable.just(Page(
        values: [last + 1, last + 2, last + 3],
        hasNext: last + 3 < 10)
      )
    },
    hasNext: { (page: Page?) -> Bool in
      return page?.hasNext == true
    }
  )
}

class Tests: XCTestCase {

  var subscription: Disposable?

  override func tearDown() {
    subscription?.dispose()
  }

  func testGetFirstPage() {
    let expectation = expectationWithDescription("get first page")
    let pager = getPager()
    subscription = pager.page
      .subscribeNext { page in
      XCTAssertEqual(page.values, [1, 2, 3])
      expectation.fulfill()
    }

    pager.next()

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testGetSecondPage() {
    let expectation = expectationWithDescription("get first two page")
    let pager = getPager()

    subscription = pager.page
      .skip(1)
      .subscribeNext { page in
        XCTAssertEqual(page.values, [4, 5, 6])
        expectation.fulfill()
    }

    pager.next()
    pager.next()
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testGetThirdPage() {
    let expectation = expectationWithDescription("get first three page")
    let pager = getPager()

    subscription = pager.page
      .skip(2)
      .subscribeNext { page in
        XCTAssertEqual(page.values, [7, 8, 9])
        expectation.fulfill()
    }

    pager.next()
    pager.next()
    pager.next()
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testCompletePager() {
    let expectation = expectationWithDescription("get completed event")
    let pager = getPager()

    subscription = pager.page
      .subscribeCompleted { _ in
        expectation.fulfill()
    }

    pager.next() // [1, 2 ,3]
    pager.next() // [4, 5, 6]
    pager.next() // [7, 8, 9]
    pager.next() // [10, 11, 12], completed
    waitForExpectationsWithTimeout(1, handler: nil)
  }
  
}
