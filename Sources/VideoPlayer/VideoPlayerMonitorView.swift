import AVFoundation
import MediaPlayer
import RxCocoa
import RxSwift
import UIKit

/// A transparent view which displays infomations from VideoPlayerMonitor.
public class VideoPlayerMonitorView: UIView {

    var enableDebugInfo = true

    public let additionalDebugInfo = BehaviorRelay<String>(value: "")

    private let textView = UITextView()
    private var monitorDisposeBag = DisposeBag()

    public var monitor: VideoPlayerMonitor? {
        didSet {
            monitorDisposeBag = DisposeBag()
            textView.text = nil

            guard let monitor = monitor else { return }

            Observable
                .combineLatest(monitor.consoleString,
                               debugInfo.startWith(""),
                               additionalDebugInfo.asObservable())
                .map(joined(separator: "\n"))
                .bind(to: textView.rx.text)
                .disposed(by: monitorDisposeBag)

        }
    }

    private var debugInfo: Observable<String> {
        let nc = NotificationCenter.default

        let isMirroring = Observable
            .merge(nc.rx.notification(UIScreen.didConnectNotification).map { _ in },
                   nc.rx.notification(UIScreen.didDisconnectNotification).map { _ in })
            .startWith(())
            .observeOn(ConcurrentMainScheduler.instance)
            .flatMap { Observable.just(UIScreen.screens.count > 1) }
            .distinctUntilChanged()

        return Observable
            .combineLatest(
                nc.rx.notification(.MPVolumeViewWirelessRoutesAvailableDidChange)
                    .map { ($0.object as! MPVolumeView).areWirelessRoutesAvailable }
                    .map { "\($0)" }
                    .startWith("")
                    .map { "MPVolumeView.areWirelessRoutesAvailable: \($0)" },

                nc.rx.notification(.MPVolumeViewWirelessRouteActiveDidChange)
                    .map { ($0.object as! MPVolumeView).isWirelessRouteActive }
                    .map { "\($0)" }
                    .startWith("")
                    .map { "MPVolumeView.isWirelessRouteActive: \($0)" },

                nc.rx.notification(AVAudioSession.routeChangeNotification)
                    .map { ($0.object as! AVAudioSession).currentRoute.outputs.map { o in "o.portType: \(o.portType), o: \(o)" } }
                    .map { "[routeChange] \($0.description)" }
                    .startWith(""),

                isMirroring.map { "[isMirroring] \($0)" }

            )
            .filter { [unowned self] _ in self.enableDebugInfo }
            .map(joined(separator: "\n"))
            .share(replay: 1, scope: .whileConnected)
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if superview == nil {
            monitor = nil
            return
        }

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        textView.textColor = .white
        addSubview(textView)

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: textView.topAnchor),
            leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            heightAnchor.constraint(equalTo: textView.heightAnchor),
            widthAnchor.constraint(equalTo: textView.widthAnchor),
        ])
    }
}

extension Array where Element == String {
    func joinNonEmpty(separator: String) -> String {
        return compactMap { s in !s.isEmpty ? s : nil }.joined(separator: separator)
    }
}

func joined(separator: String) -> (String, String) -> String {
    return {
        [$0, $1].joinNonEmpty(separator: separator)
    }
}

func joined(separator: String) -> (String, String, String) -> String {
    return {
        [$0, $1, $2].joinNonEmpty(separator: separator)
    }
}

func joined(separator: String) -> (String, String, String, String) -> String {
    return {
        [$0, $1, $2, $3].joinNonEmpty(separator: separator)
    }
}
