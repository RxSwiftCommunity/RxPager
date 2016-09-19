import PlaygroundSupport
import RxSwift
import RxPager

PlaygroundPage.current.needsIndefiniteExecution = true

// MARK: Example 1

typealias Page = [Int]
typealias Callback = () -> Void

// take previous Page, and create next one
let nextPage = { (previousPage: Page?) -> Observable<Page> in
  let last = previousPage?.last ?? 0
  return Observable.just([last + 1, last + 2, last + 3])
}

// return true if there are more pages to be emitted
let hasNext = { (page: Page) -> Bool in
  guard let last = page.last else { return true }
  return last < 10 // arbitrary condition for the demo
}

// create the pager
let trigger = PublishSubject<Void>()
let page$ = Observable.page(nextPage: nextPage, hasNext: hasNext, trigger: trigger)
let next = trigger.onNext

page$.subscribe(onNext: { print($0) })
// print [1, 2 ,3]

next() // print [4, 5, 6]
next() // print [7, 8, 9]
next() // print [10, 11, 12]

// MARK: Example 2 (page from array)

Observable
  .page(Array(1...10), by: 3, when: trigger)
  .subscribe(onNext: { print($0) })

// print [1, 2 ,3]
next() // print [4, 5, 6]
next() // print [4, 5, 6]
next() // print [10]
