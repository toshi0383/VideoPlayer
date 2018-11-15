import AVFoundation
import MediaPlayer
import RxCocoa
import RxSwift
import UIKit
import VideoPlayer

final class ViewController: UIViewController {

    private lazy var viewModel: ViewModel = {
        return ViewModel(requestRate: self.rateButton.nextRate.map { $0.rawValue },
                         requestReloadWithEnableAutoAirPlay: self.reloadButton.rx.tap
                            .map { true }
                            .throttle(1.0, scheduler: ConcurrentMainScheduler.instance),
                         requestSeekTo: self.seekBarView.slider.rx.value.asObservable()
                                            .sample(self.seekBarView.slider.rx.controlEvent(.touchUpInside))
                                            .distinctUntilChanged())
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

    /// Cached during background playback
    ///
    /// - SeeAlso: https://developer.apple.com/documentation/avfoundation/media_assets_playback_and_editing/creating_a_basic_video_player_ios_and_tvos/playing_audio_from_a_video_asset_in_the_background
    private var playerCacheForBackgroundPlayback: AVPlayer?
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
        verticalStackView.spacing = 4
        view.addSubview(verticalStackView)

        NSLayoutConstraint.activate([
            view.bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: 20),
            verticalStackView.widthAnchor.constraint(equalTo: view.widthAnchor),
            view.leadingAnchor.constraint(equalTo: verticalStackView.leadingAnchor),
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

                let periodicTime = monitor.periodicTime
                    .map { Float($0.seconds) }
                    .observeOn(ConcurrentMainScheduler.instance)
                    .share()

                // Sync subscription lifecycle with player
                let playerDisposeBag = me.viewModel.player.playerDisposeBag

                periodicTime
                    .withLatestFrom(Observable
                        .merge(me.seekBarView.slider.rx.controlEvent(.touchUp).map { true },
                               me.seekBarView.slider.rx.controlEvent(.touchDown).map { false })
                        .startWith(true)) { ($0, $1) }
                    .filter { $1 }
                    .map { $0.0 }
                    .bind(to: me.seekBarView.slider.rx.value)
                    .disposed(by: playerDisposeBag)

                Observable
                    .merge(me.seekBarView.slider.rx.value.asObservable(),
                           periodicTime)
                    .map(timeLabel)
                    .bind(to: me.seekBarView.currentTimeLabel.rx.text)
                    .disposed(by: playerDisposeBag)

                let duration = monitor.duration
                    .map { Float($0.seconds) }
                    .observeOn(ConcurrentMainScheduler.instance)
                    .share()

                duration
                    .map(timeLabel)
                    .bind(to: me.seekBarView.totalTimeLabel.rx.text)
                    .disposed(by: playerDisposeBag)

                duration
                    .subscribe(onNext: { [weak self] duration in
                        self?.seekBarView.slider.maximumValue = duration
                    })
                    .disposed(by: playerDisposeBag)

                monitor.isPlayerSeekable
                    .map { !$0 }
                    .bind(to: me.seekBarView.rx.isHidden)
                    .disposed(by: playerDisposeBag)
            })
            .disposed(by: disposeBag)

        viewModel.rateButtonRate.asObservable()
            .bind(to: rateButton.rate)
            .disposed(by: disposeBag)

        // MARK: Background Playback

        // SeeAlso: https://developer.apple.com/documentation/avfoundation/media_assets_playback_and_editing/creating_a_basic_video_player_ios_and_tvos/playing_audio_from_a_video_asset_in_the_background

        let nc = NotificationCenter.default

        Observable
            .merge(nc.rx.notification(UIApplication.didEnterBackgroundNotification).map { _ in true },
                   nc.rx.notification(UIApplication.willEnterForegroundNotification).map { _ in false })
            .observeOn(ConcurrentMainScheduler.instance)
            .subscribe(onNext: { [weak self] isDetach in
                guard let me = self else { return }

                if isDetach {
                    me.playerCacheForBackgroundPlayback = me.playerView.playerLayer.player
                    me.playerView.playerLayer.player = nil
                } else {
                    me.playerView.playerLayer.player = me.playerCacheForBackgroundPlayback
                    me.playerCacheForBackgroundPlayback = nil
                }
            })
            .disposed(by: disposeBag)

        // MARK: Log

        print("volumeView.isWirelessRouteActive: \(volumeView.isWirelessRouteActive)")
        print("volumeView.areWirelessRoutesAvailable: \(volumeView.areWirelessRoutesAvailable)")

    }
}
