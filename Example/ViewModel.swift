import AVFoundation
import VideoPlayer
import RxCocoa
import RxSwift

final class ViewModel {

    let playerRelay = PublishRelay<AVPlayer>()
    let rateButtonRate: Property<RateButton.Rate>
    let additionalDebugInfo = BehaviorRelay<String>(value: "")

    // retain (available > iOS9.3)
    private var metadataCollectorDelegate: NSObject?

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

    private var reloadDisposeBag = DisposeBag()

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
        let playPauseByApplicationState = Observable<Float>.empty()

        Observable.merge(requestRate,
                         playPauseByApplicationState.startWith(1.0))

            // NOTE: Do not apply this.
            //   `rate` can be updated by system, so you may have to update with same value.
            //
            // .distinctUntilChanged()

            .bind(to: control.setRate)
            .disposed(by: disposeBag)

        requestSeekTo
            .map { CMTime(seconds: Double($0), preferredTimescale: CMTimeScale(NSEC_PER_SEC)) }
            .bind(to: control.seekTo)
            .disposed(by: disposeBag)

        requestReloadWithEnableAutoAirPlay
            .startWith(false) // NOTE: initial load
            .flatMap { [weak self] enableAutoAirPlay -> Observable<Bool> in
                guard let me = self else { return .empty() }
                me.sendHeaderRequest(me.url) // to confirm the resource exists
                return .just(enableAutoAirPlay)
            }
            .subscribe(onNext: { [weak self] enableAutoAirPlay in
                guard let me = self else { return }

                me.reloadDisposeBag = DisposeBag()

                let factory = videoPlayerFactory ?? VideoPlayerFactory()

                let asset = AVURLAsset(url: me.url)

                /*
                 How to set AVAssetResourceLoaderDelegate to handle custom resource or license key resolution:

                 Option 1: Using Rx

                   Subscribe asset.resourceLoader.rx.loadingRequest to handle key loading requests.
                   You must call setForwardToDelegate to ignore URLs that you aren't aware of.

                   ```
                   asset.resourceLoader.rx.loadingRequest
                       .subscribe(/* resolve license etc..*/)

                   asset.resourceLoader.rx.delegate.setForwardToDelegate(yourDelegate, retainDelegate: /*up to u*/)
                   ```

                 Option 2: Not using Rx

                   ```
                   asset.resourceLoader.setDelegate(yourAssetLoaderDelegate, queue: DispatchQueue.global())
                   ```

                 TODO: Support AVContentKeySession ?
                 */


                me.player = VideoPlayer(asset: asset,
                                        control: me.control,
                                        factory: factory)

                me.player.objects.append(Something())

                me.player.player.asObservable()
                    .do(onNext: { [weak self] avplayer in
                        guard let me = self else { return }

                        // AVPlayer configuration should be done right after its initialization.

                        // e.g AirPlay by Mirroring
                        avplayer.usesExternalPlaybackWhileExternalScreenIsActive = enableAutoAirPlay

                        // e.g. more responsive playback
                        // avplayer.automaticallyWaitsToMinimizeStalling = false

                        // EXT-X-DATERANGE (In-playlist Timed Metadata)
                        // https://developer.apple.com/videos/play/wwdc2016/504/
                        if #available(iOS 9.3, *) {
                            if let playerItem = avplayer.currentItem {
                                let collector = AVPlayerItemMetadataCollector()
                                let collectorDelegate = MetadataCollectorDelegate()

                                collectorDelegate.metadataDebugInfo.asObservable()
                                    .bind(to: me.additionalDebugInfo)
                                    .disposed(by: me.reloadDisposeBag)

                                me.metadataCollectorDelegate = collectorDelegate // retain

                                collector.setDelegate(collectorDelegate, queue: DispatchQueue.main)

                                playerItem.add(collector)
                            }
                        }
                    })
                    .bind(to: me.playerRelay)
                    .disposed(by: me.reloadDisposeBag)

                requestRate
                    .map { RateButton.Rate(rawValue: $0)! }
                    .bind(to: me._rateButtonRate)
                    .disposed(by: me.reloadDisposeBag)
            })
            .disposed(by: disposeBag)

    }
}

extension ViewModel {
    func sendHeaderRequest(_ url: URL) {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        _ = URLSession.shared
            .rx.response(request: req)
            .subscribe(onNext: { (res, _) in
                print("[res.statusCode] \(res.statusCode)")
                print("[res.allHeaderFields] \(res.allHeaderFields)")
            })
    }
}

class Something {
    deinit {
        print("Something is deallocated")
    }
    init() {}
}
