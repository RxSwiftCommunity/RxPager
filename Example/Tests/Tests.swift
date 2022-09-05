import UIKit
import XCTest
import RxSwift
import RxPager
import RxCocoa

// MARK: Page

/// a sample Page Data Struct
struct Page {
  let values: [Int]
  let hasNext: Bool
}

// MARK: globals

/// Delay block after `time` seconds.
///
/// - Parameters:
///   - time: The time to wait in seconds.
///   - block: The block to executed after the delay.
func delay(_ time: TimeInterval, block: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(
    deadline: .now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: block)
}

/// Create a `Page` pager that emits 4 pages and complete.
///
/// - Returns: A tuple with the pager and the trigger.
func createPager() -> Pager<Page> {
  let nextPage = { (previousPage: Page?) -> Observable<Page> in
    let last = previousPage?.values.last ?? 0
    return Observable.just(Page(
      values: [last + 1, last + 2, last + 3],
      hasNext: last + 3 < 10)
    )
  }

  let hasNext = { (page: Page) -> Bool in
    return page.hasNext == true
  }

  return Pager(make: nextPage, while: hasNext)
}

/// Create a `Page` pager that emits 4 pages and complete.
/// Each page is emitted asynchronously after a 0.1s delay
///
/// - Returns: A tuple with the pager and the trigger
func createASyncPager() -> Pager<Page> {

  let nextPage = { (previousPage: Page?) -> Observable<Page> in
    let last = previousPage?.values.last ?? 0
    return Observable.just(Page(
      values: [last + 1, last + 2, last + 3],
      hasNext: last + 3 < 10)
      ).delaySubscription(.milliseconds(100), scheduler: MainScheduler.instance)
  }

  let hasNext = { (page: Page) -> Bool in
    return page.hasNext == true
  }

  return Pager(make: nextPage, while: hasNext)
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
    let expectation = self.expectation(description: "get first page")
    let pager = createPager()

    pager.page
      .subscribe(onNext: { page in
        XCTAssertEqual(page.values, [1, 2, 3])
        expectation.fulfill()
      })
        .disposed(by: disposeBag)

    waitForExpectations(timeout: 1, handler: nil)
  }

  /// ensure that the second page is emitted
  func testGetSecondPage() {
    let expectation = self.expectation(description: "get first two page")
    let pager = createPager()

    pager.page
      .skip(1)
      .subscribe(onNext: { page in
        XCTAssertEqual(page.values, [4, 5, 6])
        expectation.fulfill()
      })
        .disposed(by: disposeBag)

    pager.next()
    waitForExpectations(timeout: 1, handler: nil)
  }

  /// ensure that the third page is emitted
  func testGetThirdPage() {
    let expectation = self.expectation(description: "get first three page")
    let pager = createPager()

    pager.page
      .skip(2)
      .subscribe(onNext: { page in
        XCTAssertEqual(page.values, [7, 8, 9])
        expectation.fulfill()
      }).disposed(by: disposeBag)

    pager.next()
    pager.next()
    waitForExpectations(timeout: 1, handler: nil)
  }

  /// ensure that the completed event is emitted
  func testCompletePager() {
    let expectation = self.expectation(description: "get completed event")
    let pager = createPager()

    pager.page.subscribe(onCompleted: {
        expectation.fulfill()
    }).disposed(by: disposeBag)

    // starts with [1, 2 ,3]
    pager.next() // [4, 5, 6]
    pager.next() // [7, 8, 9]
    pager.next() // [10, 11, 12], completed
    waitForExpectations(timeout: 1, handler: nil)
  }

  /// ensure next is a noop when called more than once between two pages emission
  func testCantNextMoreThanOnceBeforeNextPage() {
    let expectation = self.expectation(description: "get first two page")
    let pager = createASyncPager()

    pager.page
      .subscribe(onNext: { page in
        // should only be called once
        XCTAssertEqual(page.values, [1, 2, 3])

        // wait for non event and fulfill
        delay(0.2) { expectation.fulfill() }
      })
        .disposed(by: disposeBag)

    pager.next() // should be a noop
    pager.next() // should be a noop
    waitForExpectations(timeout: 1, handler: nil)
  }

  func testPageFromSequence() {
    var pages: [[Int]] = []
    let arr = Array(0...10)
    let expected = [[0, 1], [2, 3], [4, 5], [6, 7], [8, 9], [10]]
    let expectation = self.expectation(description: "get pages from sequence")

    let trigger = PublishSubject<Void>()

    Observable
      .page(arr, by: 2, when: trigger)
      .subscribe(
        onNext: {
          pages.append($0)
        },
        onCompleted: {
          XCTAssert(pages.count == expected.count)
          zip(pages, expected).forEach { XCTAssert($0 == $1) }
          expectation.fulfill()
        }
      )
        .disposed(by: disposeBag)

    // start with [0, 1]
    trigger.onNext(()) // [2, 3]
    trigger.onNext(()) // [4, 5]
    trigger.onNext(()) // [6, 7]
    trigger.onNext(()) // [8, 9]
    trigger.onNext(()) // [10]
    waitForExpectations(timeout: 1, handler: nil)
  }
}
