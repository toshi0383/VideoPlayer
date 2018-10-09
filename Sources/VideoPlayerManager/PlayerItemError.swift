import AVFoundation

/// プレイヤーのエラー
public enum PlayerItemError {
    /// AVPlayerItemErrorLogEvent
    case notFound

    /// AVPlayerItemErrorLogEvent
    case unavailable

    /// 電話、アラーム、Siri等の割り込み処理開始時
    case beginInterruption

    /// 割り込み処理終了時
    case endInterruption

    case failedToPlayToEnd

    case stalled

    /// その他AVPlayerItemErrorLogEventに該当しない値が来た時
    case unknown

    // http://villy21.livejournal.com/12782.html
    public init(event: AVPlayerItemErrorLogEvent) {
        switch event.errorStatusCode {
        case -12938:    self = .notFound
        case -12661:    self = .unavailable
        default:        self = .unknown
        }
    }
}
