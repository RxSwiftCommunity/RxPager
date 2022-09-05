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
    public static func page(make nextPage: @escaping (Element?) -> Observable<Element>,
                            while hasNext: @escaping (Element) -> Bool,
                            when trigger: Observable<Void>) -> Observable<Element> {

        // get next page and recurse
        func next(_ fromPage: Element?) -> Observable<Element> {
            return nextPage(fromPage).map { (page: Element) -> Observable<Element> in
                guard hasNext(page) else { return Observable.just(page) }
                return Observable.concat([
                    Observable.just(page),
                    Observable.never().take(until: trigger),
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
    public static func page(_ array: [Element], by pageSize: Int,
                            when trigger: Observable<Void>) -> Observable<[Element]> {

        var index = array.startIndex

        func hasNext(_: [Element]) -> Bool {
            return index != array.endIndex
        }

        func nextPage(_: [Element]?) -> Observable<[Element]> {
            let newIndex = array.index(index, offsetBy: pageSize, limitedBy: array.endIndex) ?? array.endIndex
            let slice = array[index..<newIndex]
            index = newIndex
            return Observable<[Element]>.just(Array(slice))
        }

        return Observable<[Element]>.page(make: nextPage, while: hasNext, when: trigger)
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
