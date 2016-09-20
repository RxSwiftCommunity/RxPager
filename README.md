# RxPager

[![CI Status](http://img.shields.io/travis/pgherveou/RxPager.svg?style=flat)](https://travis-ci.org/pgherveou/RxPager)
[![Version](https://img.shields.io/cocoapods/v/RxPager.svg?style=flat)](http://cocoapods.org/pods/RxPager)
[![License](https://img.shields.io/cocoapods/l/RxPager.svg?style=flat)](http://cocoapods.org/pods/RxPager)
[![Platform](https://img.shields.io/cocoapods/p/RxPager.svg?style=flat)](http://cocoapods.org/pods/RxPager)

## Usage

```swift
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
let page$ = Observable.page(nextPage, while: hasNext, when: trigger)
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
```

See [Demo](https://github.com/pgherveou/RxPager/blob/master/Example/RxPager/PagerTableViewController.swift) for more examples

## Example

To run the example project, or run the playground, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

RxPager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "RxPager"
```

## Credits
This pod is inspired by inspired by @mttkay work https://gist.github.com/mttkay/24881a0ce986f6ec4b4d
and was refactored using ideas discussed here https://github.com/RxSwiftCommunity/RxSwiftExt/issues/30

## License

RxPager is available under the MIT license. See the LICENSE file for more info.
