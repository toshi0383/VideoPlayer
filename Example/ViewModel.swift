import AVFoundation
import VideoPlayer
import RxCocoa
import RxSwift

final class ViewModel {

    let playerRelay = PublishRelay<AVPlayer>()
    let rateButtonRate: Property<RateButton.Rate>

    private let _rateButtonRate = BehaviorRelay<RateButton.Rate>(value: .x1_0)

    // VOD
//    private let url = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/0640/0640.m3u8")!

    /// LIVE
    ///
    /// See: https://azure.microsoft.com/en-us/blog/live-247-reference-streams-available/
    private let url = URL(string: "http://b028.wpc.azureedge.net/80B028/Samples/a38e6323-95e9-4f1f-9b38-75eba91704e4/5f2ce531-d508-49fb-8152-647eba422aec.ism/Manifest(format=m3u8-aapl)")!

    private var player: VideoPlayer! {
        didSet {
            monitor = player?.monitor
        }
    }

    private(set) weak var monitor: VideoPlayerMonitor?

    private let control = VideoPlayerControl()
    private let disposeBag = DisposeBag()

    init(requestRate: Observable<Float>,
         requestReloadWithEnableAirPlay: Observable<Bool>,
         videoPlayerFactory: VideoPlayerFactoryType? = nil) {

        rateButtonRate = Property(_rateButtonRate)

        #warning("FIXME: stub")
        let isRecording = Observable.just(false)
        #warning("FIXME: stub")
        let playPauseByApplicationState = Observable<Float>.empty()

        Observable
            .combineLatest(Observable.merge(requestRate,
                                            playPauseByApplicationState.startWith(1.0)),
                           isRecording)
            .filter { !$1 }
            .map { $0.0 }
            .bind(to: control.setRate)
            .disposed(by: disposeBag)

        requestReloadWithEnableAirPlay
            .startWith(false) // NOTE: initial load
            .subscribe(onNext: { [weak self] enableAirPlay in
                guard let me = self else { return }

                let factory = videoPlayerFactory
                    ?? VideoPlayerFactory(configuration: .init(enableAirPlay: enableAirPlay))

                me.player = VideoPlayer(url: me.url,
                                        control: me.control,
                                        factory: factory)

                me.player.objects.append(Something())

                me.player.player.asObservable()
                    .bind(to: me.playerRelay)
                    .disposed(by: me.player.playerDisposeBag)

                me.player.control.setRate
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
