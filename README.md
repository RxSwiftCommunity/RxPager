# RxPager

[![CI Status](http://img.shields.io/travis/Pierre-Guillaume Herveou/RxPager.svg?style=flat)](https://travis-ci.org/Pierre-Guillaume Herveou/RxPager)
[![Version](https://img.shields.io/cocoapods/v/RxPager.svg?style=flat)](http://cocoapods.org/pods/RxPager)
[![License](https://img.shields.io/cocoapods/l/RxPager.svg?style=flat)](http://cocoapods.org/pods/RxPager)
[![Platform](https://img.shields.io/cocoapods/p/RxPager.svg?style=flat)](http://cocoapods.org/pods/RxPager)

## Usage

```swift
import RxSwift
import RxPager

let pager: Pager<[Int]> = Pager(
  
  // paging function, take previous Page, return Observable<Page>
  paging: { (previousPage: Page?) -> Observable<Page> in
    let last = previousPage?.values.last ?? 0
    return Observable.just([last + 1, last + 2, last + 3])
  },
  
  // return true if there are more pages to be emitted
  hasNext: { (page: [Int]?) -> Bool in
    return page?.last < 10
  }
)

pager
  .page
  .scan([Int]()) { $0 + $1 }
  .subscribeNext { print($0) } 

// print [1, 2 ,3]
pager.next() // print [1, 2 ,3, 4, 5, 6]
pager.next() // print [1, 2 ,3, 4, 5, 6, 7, 8, 9]
pager.next() // print [1, 2 ,3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

```

## Api

### `Pager<Page>(paging: Paging, hasNext: HasNext)`
#### `paging: (Page?) -> Observable<Page>`
Take the previous page and return the next Observable<Page>

#### `hasNext: (Page?) -> Observable<Page>>`
Take the last page and return true if there is more pages

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

RxPager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "RxPager"
```

## License

RxPager is available under the MIT license. See the LICENSE file for more info.
