import AVFoundation
import RxAVPlayer
import RxSwift

public final class MockVideoPlayerFactory: VideoPlayerFactoryType {

    public let player: AVPlayer

    /// Grab this instance to mock player state updates.
    public let stream: VideoPlayerStream

    public init(player: AVPlayer = .init(), stream: VideoPlayerStream) {
        self.player = player
        self.stream = stream
    }

    public func loadAsset(_ asset: AVURLAsset) -> Observable<Void> {
        return .just(())
    }

    public func initVideoPlayer(_ playerItem: AVPlayerItem) -> VideoPlayerType {
        return MockVideoPlayer(player: player, stream: stream)
    }
}

public final class MockVideoPlayer: VideoPlayerType {

    public let player: AVPlayer
    public let stream: VideoPlayerStream

    public init(player: AVPlayer, stream: VideoPlayerStream) {
        self.player = player
        self.stream = stream
    }
}
