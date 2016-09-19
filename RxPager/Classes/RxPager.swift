import Foundation
import RxSwift

// MARK: Observable + Pager

extension Observable {

  /// Create a Pager Observable.
  ///
  /// - parameter nextPage: The paging function used to generate each page
  /// - parameter hasNext: The hasNext function to define if there are more pages
  /// - parameter trigger: An Observable used to trigger next page load
  /// - returns: the page Observable
  public static func page(
    nextPage: @escaping (E?) -> Observable<E>,
    hasNext: @escaping (E) -> Bool,
    trigger: Observable<Void>) -> Observable<E> {

    // get next page and recurse
    func next(_ fromPage: E?) -> Observable<E> {
      return nextPage(fromPage).map { (page: E) -> Observable<E> in
        guard hasNext(page) else { return Observable.just(page) }
        return [
          Observable.just(page),
          Observable.never().takeUntil(trigger),
          next(page)
          ].concat()
        }.flatMap { $0 }
    }
    
    return next(nil)
  }

  /// Create a Pager from an array
  ///
  /// - parameter array: the array to page
  /// - by: the size of each page emitted by the pager
  /// - when: An Observable used to trigger next page load
  public static func page(_ array: [E], by pageSize: Int, when trigger: Observable<Void>) -> Observable<[E]>  {
    var index = array.startIndex

    func hasNext(_: [E]) -> Bool {
      return index != array.endIndex
    }

    func nextPage(_: [E]?) -> Observable<[E]> {
      let newIndex = array.index(index, offsetBy: pageSize, limitedBy: array.endIndex) ?? array.endIndex
      let slice = array[index..<newIndex]
      index = newIndex
      return Observable<[E]>.just(Array(slice))
    }

    return Observable<[E]>.page(nextPage: nextPage, hasNext: hasNext, trigger: trigger)
  }
}

// MARK: Pager

/// A wrapper class that encapsulate both the Pager Observable and the trigger
public struct Pager<T> {

  /// page stream
  public let page: Observable<T>

  // trigger used to call next page
  private let trigger = PublishSubject<Void>()

  public init(nextPage: @escaping (T?) -> Observable<T>, hasNext: @escaping (T) -> Bool) {
    page = Observable.page(
      nextPage: nextPage,
      hasNext: hasNext,
      trigger: trigger.asObservable()
    )
  }

  /// trigger the next page
  public func next() {
    trigger.onNext()
  }
}
