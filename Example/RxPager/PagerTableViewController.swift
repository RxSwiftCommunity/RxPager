import UIKit
import RxSwift
import RxPager

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

  /// loading indicator, placed in the tableView footer 
  /// the indicator animate until the page stream complete
  private lazy var activityIndicator: UIActivityIndicatorView = {
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    activityIndicator.frame = CGRect( origin: CGPointZero, size: CGSize(width: 44, height: 100))
    self.tableView.tableFooterView = activityIndicator
    return activityIndicator
  }()

  /// Pager, that emit pages of [Int], and complete when last emitted int is greater than 100
  let pager: Pager<[Int]> = Pager(
    paging: { (previousPage: [Int]?) -> Observable<[Int]> in
      let last = previousPage?.last ?? 0
      return Observable
        .just(Array(1...20).map { last + $0 })
        .delaySubscription(0.5, scheduler: MainScheduler.instance)
    },
    hasNext: { (page: [Int]?) -> Bool in
      return page?.last < 100
    }
  )

  override func viewDidLoad() {
    super.viewDidLoad()

    // start activity indicator
    activityIndicator.startAnimating()

    // scan, and update dataSource
    pager.page
      .scan([Int](), accumulator: +)
      .subscribeNext { [weak self] in
        self?.dataSource = $0
      }
      .addDisposableTo(disposeBag)

    // update dataSource when the stream complete
    pager
      .page
      .subscribeCompleted { [weak self] in
        self?.activityIndicator.stopAnimating()
      }
      .addDisposableTo(disposeBag)
  }

  // MARK: UITableViewController methods

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataSource.count
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCellWithIdentifier("pagerCell") else { fatalError() }
    cell.textLabel?.text = "Row \(dataSource[indexPath.row])"
    return cell
  }

  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.row == dataSource.count - 1 {
      pager.next()
    }
  }
}

