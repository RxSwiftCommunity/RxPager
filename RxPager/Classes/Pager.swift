import RxSwift

// MARK: globals

private var noOp: () -> Void = { _ in }

// MARK: Pager

final public class Pager<T> {

  // MARK: typealias

  public typealias Paging = (T?) -> Observable<T>
  public typealias HasNext = (T?) -> Bool

  // MARK: Private properties

  /// The paging function
  private let paging: Paging

  /// The hasNext function
  private let hasNext: HasNext

  /// The publishSubject used to push new pages in the page stream
  private let pages: PublishSubject<T?>

  /// delegate function called by `next()`
  private lazy var nextDelegate: () -> Void = { _ in self.pages.onNext(nil) }

  // MARK: Public properties

  /// The page stream
  public private(set) lazy var page: Observable<T> = {
    let paging = self.paging

    return self.pages
      .asObservable()
      .startWith(.None)

      // noopify next, to avoid calling more than one time per page
      .doOnNext { [weak self] _ in self?.nextDelegate = noOp }

      // get next page
      .flatMap { return paging($0) }

      // restore next and/or complete sequence
      .doOnNext { [weak self] lastPage in
        guard let pager = self else { return }
        if pager.hasNext(lastPage) {
          pager.nextDelegate = { _ in pager.pages.onNext(lastPage) }
        } else {
          pager.pages.onCompleted()
        }
      }

      // share subscription
      .shareReplay(1)
  }()

  // MARK: Initializers

  public init(paging: Paging, hasNext: HasNext) {
    self.paging = paging
    self.hasNext = hasNext
    pages = PublishSubject<T?>()
  }

  // MARK: public methods

  /// next will trigger a new page emission
  /// note that next is  a noop if called more than once before a new page emission
  public func next() {
    nextDelegate()
  }
}
