import AVFoundation
@testable import VideoPlayer
import RxSwift
import RxTest

public final class MockVideoPlayerFactory: VideoPlayerFactoryType {

    public let player: AVPlayer

    /// Grab this instance to mock player state updates.
    public let stream: VideoPlayerStream

    public init(player: AVPlayer = .init(), stream: VideoPlayerStream) {
        self.player = player
        self.stream = stream
    }

    public func makeVideoPlayer(_ asset: AVURLAsset, playerDisposeBag: DisposeBag) -> Observable<AVPlayerWrapperType> {
        return stream.isPlayable
            .map { [unowned self] _ in MockVideoPlayer(player: self.player, stream: self.stream) }
    }
}

public final class MockVideoPlayer: AVPlayerWrapperType {

    public let player: AVPlayer
    public let stream: VideoPlayerStream

    public init(player: AVPlayer, stream: VideoPlayerStream) {
        self.player = player
        self.stream = stream
    }
}
