import AVFoundation
import RxCocoa
import RxSwift
import UIKit

final class ViewController: UIViewController {

    private lazy var viewModel: ViewModel = {
        return ViewModel(requestRate: self.rateButton.nextRate.map { $0.rawValue },
                         requestReload: self.reloadButton.rx.tap
                            .throttle(1.0, scheduler: ConcurrentMainScheduler.instance))
    }()

    private let playerView: PlayerView
    private let rateButton: RateButton
    private let reloadButton: UIButton
    private let disposeBag = DisposeBag()

    init() {
        playerView = PlayerView()
        rateButton = RateButton.make()
        reloadButton = UIButton(type: .system)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK: Layout: playerView

        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: playerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            view.heightAnchor.constraint(equalTo: playerView.heightAnchor),
            view.widthAnchor.constraint(equalTo: playerView.widthAnchor),
        ])

        // MARK: Layout: rateButton

        rateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rateButton)

        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: rateButton.bottomAnchor, constant: 20),
            view.trailingAnchor.constraint(equalTo: rateButton.trailingAnchor, constant: 10),
            rateButton.widthAnchor.constraint(equalToConstant: 70),
            rateButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        // MARK: Layout: reloadButton

        reloadButton.backgroundColor = .lightGray
        reloadButton.setTitle("reload", for: .normal)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reloadButton)

        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: reloadButton.bottomAnchor, constant: 20),
            rateButton.leadingAnchor.constraint(equalTo: reloadButton.trailingAnchor, constant: 10),
            reloadButton.widthAnchor.constraint(equalToConstant: 70),
            reloadButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        // MARK: Player: load, control and monitor

        viewModel.playerRelay.asObservable()
            .observeOn(ConcurrentMainScheduler.instance)
            .subscribe(onNext: { [weak self] player in
                self?.playerView.playerLayer.player = player
            })
            .disposed(by: disposeBag)

        viewModel.rateButtonRate.asObservable()
            .bind(to: rateButton.rate)
            .disposed(by: disposeBag)
    }
}
