import AVFoundation
import VideoPlayerManager
import RxSwift

public final class MockVideoPlayerFactory: VideoPlayerFactoryType {

    public let player: AVPlayer

    /// Grab this instance to mock player state updates.
    public let stream: VideoPlayerStream

    public init(player: AVPlayer = .init(), stream: VideoPlayerStream) {
        self.player = player
        self.stream = stream
    }

    public func makeVideoPlayer(_ playerItem: AVPlayerItem) -> Observable<VideoPlayerType> {
        return .just(MockVideoPlayer(player: player, stream: stream))
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
