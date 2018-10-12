import AVFoundation
import RxCocoa
import RxSwift

/// Expresses AVPlayer states.
/// This is just for testability.
///
/// - Note: Disposed right after player initalization via Single.
public final class VideoPlayerStream {

    let requestSeekTo = PublishRelay<CMTime>()

    // MARK: control => stream

    let setRate = PublishRelay<Float>()
    let setVolume = PublishRelay<Float>()
    let setPreferredPeakBitrate = PublishRelay<Double>()

    // MARK: stream => monitor (or internal state check)

    let rate: Observable<Float>
    let isExternalPlaybackActive: Observable<Bool>
    let playerItemStatus: Observable<AVPlayerItem.Status>
    let currentTime: Observable<CMTime>
    let isPlayable: Observable<Bool>
    let assetDuration: Observable<CMTime>
    let seekableTimeRanges: Observable<[NSValue]>
    let playerError: Observable<PlayerItemError>
    let didPlayToEndTime: Observable<Void>
    let isSeeking: Observable<Bool>

    public init(isPlayable: Observable<Bool>,
                assetDuration: Observable<CMTime>,
                playerItemStatus: Observable<AVPlayerItem.Status>,
                seekableTimeRanges: Observable<[NSValue]>,
                timedMetadata: Observable<[AVMetadataItem]>,
                currentTime: Observable<CMTime>,
                rate: Observable<Float>,
                isExternalPlaybackActive: Observable<Bool>,
                setPreferredPeakBitrate: @escaping (Double) -> Void,
                setVolume: @escaping (Float) -> Void,
                seekTo: @escaping (CMTime) -> Observable<Bool>,
                setRate: @escaping (Float) -> Void,
                didPlayToEndTime: Observable<Void>,
                playerError: Observable<PlayerItemError>,
                playerDisposeBag: DisposeBag
        ) {
        self.isPlayable = isPlayable
        self.assetDuration = assetDuration
        self.rate = rate
        self.isExternalPlaybackActive = isExternalPlaybackActive
        self.playerItemStatus = playerItemStatus
        self.seekableTimeRanges = seekableTimeRanges
        self.currentTime = currentTime
        self.didPlayToEndTime = didPlayToEndTime
        self.playerError = playerError

        self.setRate
            .subscribe(onNext: { setRate($0) })
            .disposed(by: playerDisposeBag)

        self.setVolume
            .subscribe(onNext: { setVolume($0) })
            .disposed(by: playerDisposeBag)

        self.setPreferredPeakBitrate
            .subscribe(onNext: { setPreferredPeakBitrate($0) })
            .disposed(by: playerDisposeBag)

        self.isSeeking = self.requestSeekTo
            .flatMapLatest { seekTo($0) }

        self.isSeeking
            .subscribe()
            .disposed(by: playerDisposeBag)
    }
}
