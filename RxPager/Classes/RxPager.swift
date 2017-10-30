import Foundation
import RxSwift

// MARK: Observable + Pager

extension Observable {

    /// Create a Pager Observable.
    ///
    /// - Parameters:
    ///   - nextPage: The paging function used to generate new page.
    ///   - hasNext: The hasNext function to define if there are more pages.
    ///   - trigger: The Observable used to trigger next page.
    /// - Returns: The paged Observable.
    public static func page(make nextPage: @escaping (E?) -> Observable<E>,
                            while hasNext: @escaping (E) -> Bool,
                            when trigger: Observable<Void>) -> Observable<E> {

        // get next page and recurse
        func next(_ fromPage: E?) -> Observable<E> {
            return nextPage(fromPage).map { (page: E) -> Observable<E> in
                guard hasNext(page) else { return Observable.just(page) }
                return Observable.concat([
                    Observable.just(page),
                    Observable.never().takeUntil(trigger),
                    next(page)
                    ])
                }.flatMap { $0 }
        }

        return next(nil)
    }

    /// Create a Pager from an array
    ///
    /// - Parameters:
    ///   - array: The array to page
    ///   - pageSize: The size of each page emitted by the pager.
    ///   - trigger: An Observable used to trigger next page load.
    /// - Returns: The paged Observable.
    public static func page(_ array: [E], by pageSize: Int,
                            when trigger: Observable<Void>) -> Observable<[E]> {

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

        return Observable<[E]>.page(make: nextPage, while: hasNext, when: trigger)
    }
}

// MARK: Pager

/// A wrapper class that encapsulate both the Pager Observable and the trigger
public struct Pager<T> {

    /// page stream
    public let page: Observable<T>

    // trigger used to call next page
    private let trigger = PublishSubject<Void>()

    /// Create a Pager
    ///
    /// - parameter nextPage: The paging function used to generate new page
    /// - parameter hasNext: The hasNext function to define if there are more pages
    public init(make nextPage: @escaping (T?) -> Observable<T>, while hasNext: @escaping (T) -> Bool) {
        page = Observable.page(make: nextPage, while: hasNext, when: trigger.asObservable())
    }

    /// trigger the next page
    public func next() {
        trigger.onNext(())
    }
}
