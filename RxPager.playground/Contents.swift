//: Playground - noun: a place where people can play

//: Please build the scheme 'RxPagerPlayground' first
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

import RxSwift
import RxPager

typealias Page = [Int]
typealias Callback = () -> Void

// paging function, take previous Page, return Observable<Page>
let paging = { (previousPage: Page?) -> Observable<Page> in
  let last = previousPage?.last ?? 0
  return Observable.just([last + 1, last + 2, last + 3])
}

// return true if there are more pages to be emitted
let hasNext = { (page: Page) -> Bool in
  return page.last < 10 // arbitrary condition for the demo
}

// create the pager
let trigger = PublishSubject<Void>()
let pager: (page: Observable<Page>, next: Callback) = (
  page: rx_pager(paging: paging, hasNext: hasNext, trigger: trigger),
  next: { _ in trigger.onNext() }
)

// or using Pager struct directly
// let pager: Pager<Page> = Pager(
//   paging: paging,
//   hasNext: hasNext
// )

pager
  .page
  .scan(Page()) { $0 + $1 }
  .subscribeNext { print($0) }

// print [1, 2 ,3]
pager.next() // print [1, 2 ,3, 4, 5, 6]
pager.next() // print [1, 2 ,3, 4, 5, 6, 7, 8, 9]
pager.next() // print [1, 2 ,3, 4, 5, 6, 7, 8, 9, 10, 11, 12]