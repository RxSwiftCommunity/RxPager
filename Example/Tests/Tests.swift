import UIKit
import XCTest
import RxSwift
import RxPager

// MARK: Page

/// a sample Page Data Struct
struct Page {
  let values: [Int]
  let hasNext: Bool
}

// MARK: globals

/// delay block after `time` seconds
///
/// - parameter time: The time to wait in seconds
/// - parameter block: The block to executed after the delay
func delay(time: NSTimeInterval, block: () -> Void) {
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC))),
    dispatch_get_main_queue(), block)
}

/// create a `Page` pager that emits 4 pages and complete
///
/// - returns: a tuple with the pager and the trigger
func createPager() -> (page: Observable<Page>, next: () -> Void) {
  let paging = { (previousPage: Page?) -> Observable<Page> in
    let last = previousPage?.values.last ?? 0
    return Observable.just(Page(
      values: [last + 1, last + 2, last + 3],
      hasNext: last + 3 < 10)
    )
  }

  let hasNext = { (page: Page) -> Bool in
    return page.hasNext == true
  }

  let trigger = PublishSubject<Void>()

  return (
    page: rx_pager(
      paging: paging,
      hasNext: hasNext,
      trigger: trigger.asObservable()
    ),
    next: { trigger.onNext() }
  )
}

/// create a `Page` pager that emits 4 pages and complete
/// each page is emitted asynchronously after a 0.1s delay
///
/// - returns: a tuple with the pager and the trigger
func createASyncPager() -> (page: Observable<Page>, next: () -> Void) {

  let paging = { (previousPage: Page?) -> Observable<Page> in
    let last = previousPage?.values.last ?? 0
    return Observable.just(Page(
      values: [last + 1, last + 2, last + 3],
      hasNext: last + 3 < 10)
      ).delaySubscription(0.1, scheduler: MainScheduler.instance)
  }

  let hasNext = { (page: Page) -> Bool in
    return page.hasNext == true
  }

  let trigger = PublishSubject<Void>()

  return (
    page: rx_pager(
      paging: paging,
      hasNext: hasNext,
      trigger: trigger.asObservable()
    ),
    next: { trigger.onNext() }
  )
}

// MARK: Tests

class Tests: XCTestCase {

  /// stream dispose bag
  var disposeBag = DisposeBag()

  override func tearDown() {
    // dispose current `disposeBag` and create a new one
    disposeBag = DisposeBag()
  }

  /// ensure that the first page is emitted
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

  /// ensure that the second page is emitted
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

  /// ensure that the third page is emitted
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

  /// ensure that the completed event is emitted
  func testCompletePager() {
    let expectation = expectationWithDescription("get completed event")
    let pager = createPager()

    let sharedPager = pager.page.shareReplay(1)

    sharedPager
      .subscribeNext { print($0) }
      .addDisposableTo(disposeBag)

    sharedPager
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

  /// ensure next is a noop when called more than once between two pages emission
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

    pager.next() // should be a noop
    pager.next() // should be a noop
    waitForExpectationsWithTimeout(1, handler: nil)
  }
}
