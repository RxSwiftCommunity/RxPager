import RxSwift

/// create a Pager Observable
///
/// - parameter paging: The paging function used to generate each page
/// - parameter hasNext: The hasNext function to define if there are more pages
/// - parameter trigger: The trigger Observable used to trigger next page load
/// - returns: the page Observable
public func rx_pager<T>(
  paging paging: (T?) -> Observable<T>,
         hasNext: (T) -> Bool,
         trigger: Observable<Void>) -> Observable<T> {

  // get next page and recurse
  func next(current: T?) -> Observable<T> {
    return paging(current).map { (nextPage: T) -> Observable<T> in
      guard hasNext(nextPage) else { return Observable.just(nextPage) }
      return [
        Observable.just(nextPage),
        Observable.never().takeUntil(trigger),
        next(nextPage)
        ].concat()
      }.flatMap { $0 }
  }

  return next(nil)
}

// MARK: Pager

/// A wrapper class that encapsulate both the Pager Observable and the trigger
final public class Pager<T> {

  /// page stream
  public let page: Observable<T>

  // trigger used to call next page
  private let trigger = PublishSubject<Void>()

  public init(paging: (T?) -> Observable<T>, hasNext: (T) -> Bool) {
    page = rx_pager(
      paging: paging,
      hasNext: hasNext,
      trigger: trigger.asObservable()
    )
  }

  /// trigger the next page
  public func next() {
    trigger.onNext()
  }
}
