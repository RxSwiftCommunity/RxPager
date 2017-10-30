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

    /// wether we should show the animating cell or not
    private var showAnimatingCell = true

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

    /// Pager, that emit pages of [Int], and complete when last emitted int is greater than 100
    private lazy var page: Observable<[Int]> = {
        func nextPage(_ previousPage: [Int]?) -> Observable<[Int]> {
            let last = previousPage?.last ?? 0
            return Observable
                .just(Array(1...20).map { last + $0 })
                .delaySubscription(0.5, scheduler: MainScheduler.instance)
        }

        func hasNext(_ page: [Int]?) -> Bool {
            guard let last = page?.last else { return true }
            return last < 100
        }

        return Observable.page(make: nextPage, while: hasNext, when: self.loadNextPageTrigger)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // scan, and update dataSource
        page
            .scan([Int](), accumulator: +)
            .subscribe(onNext: { [weak self] in self?.dataSource = $0 })
            .disposed(by: disposeBag)

        // update dataSource and reset the animating flag, when the stream complete
        page
            .subscribe(onCompleted: { [weak self] in
                self?.showAnimatingCell = false
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    // MARK: UITableViewController methods

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count + (showAnimatingCell ? 1 : 0)
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell?

        if showAnimatingCell && indexPath.row == dataSource.count {
            cell = tableView.dequeueReusableCell(withIdentifier: "loadingCell")
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "pagerCell")
            cell?.textLabel?.text = "Row \(dataSource[(indexPath as NSIndexPath).row])"
        }

        return cell!
    }
}
