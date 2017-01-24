# Demo App

Build and Run the RxPager-Example target from Xcode.
The demo app display a simple tableview with a paged datasource

![demo](http://pgherveou.github.io/RxPager/demo.gif)

```swift
override func viewDidLoad() {
    super.viewDidLoad()

    // scan, and update dataSource
    page
        .scan([Int](), accumulator: +)
        .subscribe(onNext: { [weak self] in self?.dataSource = $0 })
        .addDisposableTo(disposeBag)

    // update dataSource and reset the animating flag, when the stream complete 
    page
        .subscribe(onCompleted: { [weak self] in
            self?.showAnimatingCell = false
            self?.tableView.reloadData()
        })
        .addDisposableTo(disposeBag)
}
```    
