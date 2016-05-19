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

/// delay block after `time` seconds
func delay(time: Double, block: () -> Void) {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC))),
    dispatch_get_main_queue(), block)
}

/// page factory helper
func createPager() -> Pager<Page> {
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

func createASyncPager() -> Pager<Page> {
  return Pager(
    paging: { (previousPage: Page?) -> Observable<Page> in
      let last = previousPage?.values.last ?? 0
      return Observable.just(Page(
        values: [last + 1, last + 2, last + 3],
        hasNext: last + 3 < 10)
        ).delaySubscription(0.1, scheduler: MainScheduler.instance)
    },
    hasNext: { (page: Page?) -> Bool in
      return page?.hasNext == true
    }
  )
}

class Tests: XCTestCase {

  var disposeBag = DisposeBag()

  override func tearDown() {
    disposeBag = DisposeBag()
  }

  func testGetFirstPage() {
    let expectation = expectationWithDescription("get first page")
    let pager = createPager()
    pager.page
      .subscribeNext { page in
        XCTAssertEqual(page.values, [1, 2, 3])
        expectation.fulfill()
      }
      .addDisposableTo(disposeBag)

    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testGetSecondPage() {
    let expectation = expectationWithDescription("get first two page")
    let pager = createPager()

    pager.page
      .skip(1)
      .subscribeNext { page in
        XCTAssertEqual(page.values, [4, 5, 6])
        expectation.fulfill()
      }
      .addDisposableTo(disposeBag)

    pager.next()
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testGetThirdPage() {
    let expectation = expectationWithDescription("get first three page")
    let pager = createPager()

    pager.page
      .skip(2)
      .subscribeNext { page in
        XCTAssertEqual(page.values, [7, 8, 9])
        expectation.fulfill()
      }.addDisposableTo(disposeBag)

    pager.next()
    pager.next()
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testCompletePager() {
    let expectation = expectationWithDescription("get completed event")
    let pager = createPager()

    pager.page
      .subscribeCompleted { _ in
        expectation.fulfill()
      }
      .addDisposableTo(disposeBag)

    // starts with [1, 2 ,3]
    pager.next() // [4, 5, 6]
    pager.next() // [7, 8, 9]
    pager.next() // [10, 11, 12], completed
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testCantNextMoreThanOnceBeforeNextPage() {
    let expectation = expectationWithDescription("get first two page")
    let pager = createASyncPager()

    pager.page
      .subscribeNext { page in
        // should only be called once
        XCTAssertEqual(page.values, [1, 2, 3])

        // wait for non event and fulfill
        delay(0.2) { expectation.fulfill() }
      }
      .addDisposableTo(disposeBag)

    pager.next()
    pager.next() // should be a noop
    pager.next() // should be a noop
    waitForExpectationsWithTimeout(1, handler: nil)
  }
  
}
