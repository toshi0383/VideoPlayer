import AVFoundation
import RxCocoa
import RxSwift
import UIKit

final class ViewController: UIViewController {

    let url = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/0640/0640.m3u8")!

    let control = VideoPlayerControl()

    var manager: VideoPlayerManager!

    private let playerView: PlayerView
    private let rateButton: RateButton
    private let reloadButton: UIButton

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

        rateButton.nextRate
            .startWith(.x1_0)
            .map { $0.rawValue }
            .bind(to: control.setRate)
            .disposed(by: rx.disposeBag)

        reloadButton.rx.tap
            .throttle(1.0, scheduler: ConcurrentMainScheduler.instance)
            .startWith(())
            .observeOn(ConcurrentMainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let me = self else { return }
                me.manager = VideoPlayerManager(url: me.url, control: me.control)

                me.manager.player.asObservable()
                    .observeOn(ConcurrentMainScheduler.instance)
                    .subscribe(onNext: { [weak self] player in
                        self?.playerView.playerLayer.player = player
                    })
                    .disposed(by: me.rx.disposeBag)

                me.manager.monitor.rate
                    .map { RateButton.Rate(rawValue: $0) }
                    .filterNil()
                    .bind(to: me.rateButton.rate)
                    .disposed(by: me.rx.disposeBag)
            })
            .disposed(by: rx.disposeBag)
    }
}
