import RxSwift

// MARK: globals

private var noOp: () -> Void = { _ in }

// MARK: Pager

final public class Pager<T> {

  // MARK: typealias

  public typealias Paging = (T?) -> Observable<T>
  public typealias HasNext = (T?) -> Bool

  // MARK: Private properties

  private let paging: Paging
  private let hasNext: HasNext
  lazy private var nextDelegate: () -> Void = { _ in self.pages.onNext(nil) }

  private let pages: PublishSubject<T?>

  // MARK: Public properties

  lazy public var page: Observable<T> = {
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

  public func next() {
    nextDelegate()
  }
}
