import AVFoundation
import MediaPlayer
import RxCocoa
import RxSwift
import UIKit
import VideoPlayer

final class ViewController: UIViewController {

    private lazy var viewModel: ViewModel = {
        return ViewModel(requestRate: self.rateButton.nextRate.map { $0.rawValue },
                         requestReloadWithEnableAirPlay: self.reloadButton.rx.tap
                            .map { true }
                            .throttle(1.0, scheduler: ConcurrentMainScheduler.instance))
    }()

    private let playerView: PlayerView
    private let monitorView: VideoPlayerMonitorView
    private let stackView: UIStackView
    private let rateButton: RateButton
    private let volumeView: MPVolumeView
    private let reloadButton: UIButton
    private let toggleMonitorButton: UIButton
    private let disposeBag = DisposeBag()

    init() {
        playerView = PlayerView()
        monitorView = VideoPlayerMonitorView()
        stackView = UIStackView(arrangedSubviews: [])
        rateButton = RateButton.make()
        reloadButton = UIButton(type: .system)
        toggleMonitorButton = UIButton(type: .system)
        volumeView = MPVolumeView()

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

        // MARK: Layout: monitorView

        monitorView.translatesAutoresizingMaskIntoConstraints = false
        playerView.addSubview(monitorView)

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: monitorView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: monitorView.leadingAnchor),
            playerView.heightAnchor.constraint(equalTo: monitorView.heightAnchor),
            playerView.widthAnchor.constraint(equalTo: monitorView.widthAnchor),
        ])

        // MARK: Layout: stackView

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor),
            view.centerXAnchor.constraint(equalTo: stackView.centerXAnchor, constant: 10),
        ])

        // MARK: Layout: rateButton

        rateButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(rateButton)

        // MARK: Layout: reloadButton

        reloadButton.backgroundColor = .lightGray
        reloadButton.setTitle("reload", for: .normal)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(reloadButton)

        // MARK: Layout: volumeView
        volumeView.translatesAutoresizingMaskIntoConstraints = false
        volumeView.showsVolumeSlider = false
        stackView.addArrangedSubview(volumeView)

        NSLayoutConstraint.activate([
            volumeView.widthAnchor.constraint(equalToConstant: 70),
            volumeView.heightAnchor.constraint(equalToConstant: 50),
        ])

        // MARK: Layout: toggleMonitorButton

        toggleMonitorButton.backgroundColor = .lightGray
        toggleMonitorButton.setTitle("monitor", for: .normal)
        toggleMonitorButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(toggleMonitorButton)

        toggleMonitorButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let v = self?.monitorView else {
                    return
                }

                v.isHidden = !v.isHidden
            })
            .disposed(by: disposeBag)

        // MARK: Player: load, control and monitor

        viewModel.playerRelay.asObservable()
            .observeOn(ConcurrentMainScheduler.instance)
            .subscribe(onNext: { [weak self] player in
                guard let me = self else { return }

                me.playerView.playerLayer.player = player
                me.monitorView.monitor = me.viewModel.monitor
            })
            .disposed(by: disposeBag)

        viewModel.rateButtonRate.asObservable()
            .bind(to: rateButton.rate)
            .disposed(by: disposeBag)

        // MARK: Log

        print("volumeView.isWirelessRouteActive: \(volumeView.isWirelessRouteActive)")
        print("volumeView.areWirelessRoutesAvailable: \(volumeView.areWirelessRoutesAvailable)")

        let nc = NotificationCenter.default
        _ = nc.rx.notification(.MPVolumeViewWirelessRoutesAvailableDidChange)
            .debug("[MPVolumeViewWirelessRoutesAvailableDidChange]")
            .subscribe()
        _ = nc.rx.notification(.MPVolumeViewWirelessRouteActiveDidChange)
            .debug("[MPVolumeViewWirelessRouteActiveDidChange]")
            .subscribe()
    }
}
