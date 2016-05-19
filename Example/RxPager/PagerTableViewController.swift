import UIKit
import RxSwift
import RxPager

// MARK: PagerTableViewController

class PagerTableViewController: UITableViewController {

  var dataSource: [Int] = [] {
    didSet {
      tableView.reloadData()
    }
  }
  
  let disposeBag = DisposeBag()
  weak var activityIndicator: UIActivityIndicatorView?

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

    // setup activity indicator
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    activityIndicator.frame = CGRect( origin: CGPointZero, size: CGSize(width: 44, height: 100))
    tableView.tableFooterView = activityIndicator
    self.activityIndicator = activityIndicator

    // setup page subscription
    pager.page
      .scan([Int](), accumulator: +)
      .subscribeNext { [weak self] in
        self?.activityIndicator?.startAnimating()
        self?.dataSource = $0
      }
      .addDisposableTo(disposeBag)

    pager
      .page
      .subscribeCompleted {
        self.activityIndicator?.stopAnimating()
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

