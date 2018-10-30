import AVFoundation
import VideoPlayer
import RxCocoa
import RxSwift

final class ViewModel {

    let playerRelay = PublishRelay<AVPlayer>()
    let rateButtonRate: Property<RateButton.Rate>

    private let _rateButtonRate = BehaviorRelay<RateButton.Rate>(value: .x1_0)

    // VOD
    private let url = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/0640/0640.m3u8")!

    /// LIVE
    ///
    /// See: https://azure.microsoft.com/en-us/blog/live-247-reference-streams-available/
//    private let url = URL(string: "http://b028.wpc.azureedge.net/80B028/Samples/a38e6323-95e9-4f1f-9b38-75eba91704e4/5f2ce531-d508-49fb-8152-647eba422aec.ism/Manifest(format=m3u8-aapl)")!

    private(set) var player: VideoPlayer! {
        didSet {
            monitor = player?.monitor
        }
    }

    private(set) weak var monitor: VideoPlayerMonitor?

    private let control = VideoPlayerControl()
    private let disposeBag = DisposeBag()

    /// Initializes ViewModel
    ///
    /// - Parameters:
    ///   - requestRate: Rate which you want to play.
    ///   - requestReloadWithEnableAutoAirPlay: AutoAirPlay means that if AirPlay should (not) start when detected mirroring mode.
    ///   - requestSeekTo: Seek position.
    ///   - videoPlayerFactory: VideoPlayerFactoryType. Uses VideoPlayerFactory if nil.
    init(requestRate: Observable<Float>,
         requestReloadWithEnableAutoAirPlay: Observable<Bool>,
         requestSeekTo: Observable<Float>,
         videoPlayerFactory: VideoPlayerFactoryType? = nil) {

        rateButtonRate = Property(_rateButtonRate)

        #warning("FIXME: stub")
        let isRecording = Observable.just(false)
        #warning("FIXME: stub")
        let playPauseByApplicationState = Observable<Float>.empty()

        Observable

            // NOTE: Restrict playback by blocking setRate stream like this.
            //   This is just an example.
            .combineLatest(Observable.merge(requestRate,
                                            playPauseByApplicationState.startWith(1.0)),
                           isRecording)
            .map { $0.1 ? 0.0 : $0.0 }

            // NOTE: Do not apply this.
            //   `rate` can be updated by system, so you may have to update with same value.
            //
            // .distinctUntilChanged()

            .bind(to: control.setRate)
            .disposed(by: disposeBag)

        requestSeekTo
            .debug("[requestSeekTo]")
            .map { CMTime(seconds: Double($0), preferredTimescale: CMTimeScale(NSEC_PER_SEC)) }
            .bind(to: control.seekTo)
            .disposed(by: disposeBag)

        requestReloadWithEnableAutoAirPlay
            .startWith(false) // NOTE: initial load
            .subscribe(onNext: { [weak self] enableAutoAirPlay in
                guard let me = self else { return }

                let factory = videoPlayerFactory
                    ?? VideoPlayerFactory()

                me.player = VideoPlayer(url: me.url,
                                        control: me.control,
                                        factory: factory)

                me.player.objects.append(Something())

                me.player.player.asObservable()
                    .do(onNext: { avplayer in
                        // AVPlayer configuration should be done right after its initialization.

                        // e.g AirPlay by Mirroring
                        avplayer.usesExternalPlaybackWhileExternalScreenIsActive = enableAutoAirPlay

                        // e.g. more responsive playback
                        // avplayer.automaticallyWaitsToMinimizeStalling = false
                    })
                    .bind(to: me.playerRelay)
                    .disposed(by: me.player.playerDisposeBag)

                requestRate
                    .map { RateButton.Rate(rawValue: $0)! }
                    .bind(to: me._rateButtonRate)
                    .disposed(by: me.player.playerDisposeBag)
            })
            .disposed(by: disposeBag)

    }
}

class Something {
    deinit {
        print("Something is deallocated")
    }
    init() {}
}
