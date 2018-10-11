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
    let playerItemStatus: Observable<AVPlayerItem.Status>
    let currentTime: Observable<CMTime>
    let isPlayable: Observable<Bool>
    let seekableTimeRanges: Observable<[NSValue]>
    let playerError: Observable<PlayerItemError>
    let didPlayToEndTime: Observable<Void>

    // MARK: player => stream

    let isPlayerSeeking = PublishRelay<Bool>()

    // MARK: Private

    private let disposeBag = DisposeBag()

    /// - parameter seekTo: Seek player
    public init(isPlayable: Observable<Bool>,
                assetDuration: Observable<CMTime>,
                playerItemStatus: Observable<AVPlayerItem.Status>,
                seekableTimeRanges: Observable<[NSValue]>,
                timedMetadata: Observable<[AVMetadataItem]>,
                currentTime: Observable<CMTime>,
                rate: Observable<Float>,
                setPreferredPeakBitrate: @escaping (Double) -> Void,
                setVolume: @escaping (Float) -> Void,
                seekTo: @escaping (CMTime) -> Observable<Bool>,
                setRate: @escaping (Float) -> Void,
                didPlayToEndTime: Observable<Void>,
                playerError: Observable<PlayerItemError>
        ) {
        self.isPlayable = isPlayable
        self.rate = rate
        self.playerItemStatus = playerItemStatus
        self.seekableTimeRanges = seekableTimeRanges
        self.currentTime = currentTime
        self.didPlayToEndTime = didPlayToEndTime
        self.playerError = playerError

        self.setRate
            .subscribe(onNext: { setRate($0) })
            .disposed(by: disposeBag)

        self.setVolume
            .subscribe(onNext: { setVolume($0) })
            .disposed(by: disposeBag)

        self.setPreferredPeakBitrate
            .subscribe(onNext: { setPreferredPeakBitrate($0) })
            .disposed(by: disposeBag)

    }
}
