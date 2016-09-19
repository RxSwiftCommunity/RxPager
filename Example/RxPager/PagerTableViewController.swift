import UIKit
import RxSwift
import RxCocoa
import RxPager

// MARK: Helper

private let startLoadingOffset: CGFloat = 20.0
private func isNearTheBottomEdge(_ contentOffset: CGPoint, _ tableView: UITableView) -> Bool {
  return contentOffset.y +
    tableView.frame.size.height +
    startLoadingOffset > tableView.contentSize.height
}

// MARK: PagerTableViewController

class PagerTableViewController: UITableViewController {

  /// Observable disposeBag
  private let disposeBag = DisposeBag()

  /// tableview dataSource
  private var dataSource: [Int] = [] {
    didSet {
      tableView.reloadData()
    }
  }

  /// pager trigger
  private lazy var loadNextPageTrigger: Observable<Void> = {
    return self.tableView.rx.contentOffset
      .flatMap { (offset) -> Observable<Void> in
        isNearTheBottomEdge(offset, self.tableView)
          ? Observable.just(Void())
          : Observable.empty()
    }
  }()

  /// loading indicator, placed in the tableView footer
  /// the indicator animate until the page stream complete
  private lazy var activityIndicator: UIActivityIndicatorView = {
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    activityIndicator.frame = CGRect(
      origin: CGPoint.zero,
      size: CGSize(width: 44, height: 100)
    )
    self.tableView.tableFooterView = activityIndicator
    return activityIndicator
  }()

  /// Pager, that emit pages of [Int], and complete when last emitted int is greater than 100
  private lazy var page: Observable<[Int]> = {
    func makePage(_ previousPage: [Int]?) -> Observable<[Int]> {
      let last = previousPage?.last ?? 0
      return Observable
        .just(Array(1...20).map { last + $0 })
        .delaySubscription(0.5, scheduler: MainScheduler.instance)
    }

    func hasNext(_ page: [Int]?) -> Bool {
      guard let last = page?.last else { return true }
      return last < 100
    }

    return Observable.page(
      nextPage: makePage,
      hasNext: hasNext,
      trigger: self.loadNextPageTrigger
    )
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    // start activity indicator
    activityIndicator.startAnimating()

    // scan, and update dataSource
    page
      .scan([Int](), accumulator: +)
      .subscribe(onNext: { [weak self] in self?.dataSource = $0 })
      .addDisposableTo(disposeBag)

    // update dataSource when the stream complete
    page
      .subscribe(onCompleted: {
        [weak self] in self?.activityIndicator.stopAnimating()
        })
      .addDisposableTo(disposeBag)
  }

  // MARK: UITableViewController methods

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataSource.count
  }

  override func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "pagerCell") else { fatalError() }
    cell.textLabel?.text = "Row \(dataSource[(indexPath as NSIndexPath).row])"
    return cell
  }
}
