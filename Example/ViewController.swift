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
                            .throttle(1.0, scheduler: ConcurrentMainScheduler.instance),
                         requestSeekTo: self.seekBarView.slider.rx.value.asObservable())
    }()

    private let playerView = PlayerView()
    private let seekBarView = SeekBarView()
    private let monitorView = VideoPlayerMonitorView()
    private let stackView = UIStackView()
    private let verticalStackView = UIStackView()
    private let rateButton = RateButton.make()
    private let volumeView = MPVolumeView()
    private let reloadButton = UIButton(type: .system)
    private let toggleMonitorButton = UIButton(type: .system)
    private let disposeBag = DisposeBag()
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
        view.addSubview(monitorView)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: monitorView.topAnchor),
            view.leadingAnchor.constraint(equalTo: monitorView.leadingAnchor),
            view.heightAnchor.constraint(equalTo: monitorView.heightAnchor),
            view.widthAnchor.constraint(equalTo: monitorView.widthAnchor),
        ])

        // MARK: Layout: verticalStackView

        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.distribution = .equalSpacing
        verticalStackView.spacing = 8
        view.addSubview(verticalStackView)

        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: 20),
            verticalStackView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor),
            view.centerXAnchor.constraint(equalTo: verticalStackView.centerXAnchor, constant: 10),
        ])

        // MARK: Layout: seekBarView

        seekBarView.translatesAutoresizingMaskIntoConstraints = false
        verticalStackView.addArrangedSubview(seekBarView)

        // MARK: Layout: stackView

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 10
        verticalStackView.addArrangedSubview(stackView)

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

                guard let monitor = me.viewModel.monitor else { return }

                me.monitorView.monitor = monitor

                let duration = monitor.duration
                    .map { $0.seconds }
                    .share()
                    .observeOn(ConcurrentMainScheduler.instance)

                duration
                    .map { time in
                        let hour = Int(time / (60 * 60))
                        let minutes = Int((time / 60).truncatingRemainder(dividingBy: 60))
                        let second = Int(time.truncatingRemainder(dividingBy: 60))
                        let hourText = hour > 0 ? "\(String(format: "%02d", hour)):" : ""
                        return "\(hourText)\(String(format: "%02d", minutes)):\(String(format: "%02d", second))"
                    }
                    .bind(to: me.seekBarView.totalTimeLabel.rx.text)
                    .disposed(by: me.disposeBag)

                duration
                    .subscribe(onNext: { [weak self] duration in
                        self?.seekBarView.slider.maximumValue = Float(duration)
                        self?.seekBarView.slider.value = 0
                    })
                    .disposed(by: me.disposeBag)
            })
            .disposed(by: disposeBag)

        viewModel.rateButtonRate.asObservable()
            .bind(to: rateButton.rate)
            .disposed(by: disposeBag)

        // MARK: Log

        print("volumeView.isWirelessRouteActive: \(volumeView.isWirelessRouteActive)")
        print("volumeView.areWirelessRoutesAvailable: \(volumeView.areWirelessRoutesAvailable)")

    }
}
