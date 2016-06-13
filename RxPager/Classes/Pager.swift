import RxSwift

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

final public class Pager<T> {

  /// closure to trigger next page
  public let next: () -> Void

  /// page stream
  public let page: Observable<T>

  public init(
    paging: (T?) -> Observable<T>,
    hasNext: (T) -> Bool) {

    // create next trigger with a PublishSubject
    let trigger = PublishSubject<Void>()
    next = { _ in trigger.onNext() }

    self.page = rx_pager(
      paging: paging,
      hasNext: hasNext,
      trigger: trigger.asObservable()
    )
  }
}
